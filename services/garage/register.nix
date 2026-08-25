{lib, inputs, config, pkgs, ...}:

let 
    topology = config.infra.topology;
    domain = topology.domain;

    owner = "garage";
    reload = ["garage.service"];
    filemode = "0400";
    opensslSize = 32;
    opensslType = "hex";
    
    extraNginxConfig = {
        virtualHosts."s3.${domain}".extraConfig = 
            ''
                    proxy_request_buffering off;
                    proxy_buffering off;
                    proxy_http_version 1.1;
                    proxy_read_timeout 1h;
                    proxy_send_timeout 1h;
                    send_timeout 3600s;
                    client_body_timeout 3600s;

                    proxy_set_header Host $host;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header Connection "";
                    proxy_set_header Transfer-Encoding "";

                    keepalive_timeout 65s;

            '';
            clientMaxBodySize = "100G";
    };


in {

config.infra.services.garage = {
    users = [{name = "garage"; uid=10001;}];
    store.passwords = [
        {filename = "garage-rpc.key"; inherit owner reload opensslSize opensslType;}
        {filename = "garage-admin.key"; inherit owner reload opensslSize opensslType;}
        {filename = "garage-metrics.key"; inherit owner reload opensslSize opensslType;}
    ];
    persistent = [
        {path="/var/lib/garage/data"; inherit owner reload; mode = "0700";}
        {path="/var/lib/garage/meta"; inherit owner reload; mode = "0700";}
    ];
    endpoints.http = [
        {hostname="s3.${domain}"; port=3900; inherit extraNginxConfig;}
        {hostname="s3-admin.${domain}"; port=3903;}
    ];
};
}


