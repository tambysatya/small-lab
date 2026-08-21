{inputs, config, lib, pkgs,...}:

let
 
    topology= config.infra.topology;
    hostname = "nextcloud.${topology.domain}";
    owner = "nextcloud";
    reload = ["phpfpm.service" "nextcloud-setup.service"];
    extraNginxConfig = {
        virtualHosts.${hostname}.extraConfig = 
            ''
                proxy_request_buffering off;
                proxy_buffering off;
                proxy_http_version 1.1;
                proxy_read_timeout 1h;
                proxy_send_timeout 1h;
                send_timeout 3600s;

                keepalive_timeout 65s;
                proxy_set_header Connection "";

                client_body_timeout 3600s;
                fastcgi_request_buffering off;
                fastcgi_read_timeout 3600s;


            '';
        clientMaxBodySize = "100G";
    };




    endpoints = [{
                   host = hostname;
                   port = 80; 
                   is_http = true; #use port redirection instead of nginx + TLS
                 }];
    secret = {names = ["nextcloud-admin.key"]; owner="nextcloud"; reload=["phpfmp.service"]; kind = {provider="openssl";};};
in {

infra.services.nextcloud = {
    users = [{name="nextcloud"; uid=10003;}];
    files = {
        passwords = [
            {filename = "nextcloud-admin.key"; opensslType = "base64"; opensslSize=64; inherit owner reload;}
        ];
        postgres = [
            {database = "nextcloud"; inherit owner reload;}
        ];
        s3 = [
            {bucket = "nextcloud"; inherit owner reload;}
        ];
    };
    persistent = [
        {path="/var/lib/nextcloud/config"; inherit owner reload;}
        {path="/var/lib/nextcloud/data"; inherit owner reload;}
    ];
    endpoints.http = [{inherit hostname extraNginxConfig; port=80;}];

};

}

