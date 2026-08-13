{lib, inputs, config, infra, vmname, vmconf, pkgs,...}:

let 
    infralib = import ../infra/lib.nix {inherit lib vmconf vmname;};
    reg = import ../registry/lib/register.nix {inherit inputs lib vmname infra vmconf;};
    secrets = {
		/* Admin secrets */
		"garage-rpc.key" = {path = "/var/lib/garage/garage-rpc.key";};
		"garage-admin.key" = {path = "/var/lib/garage/garage-admin.key";};
		"garage-metrics.key" = {path = "/var/lib/garage/garage-metrics.key";};
	};
    endpoints = [
        {
            host = "s3.${infra.domain}";
            port = 3900;
             extraNginxConfig = {
                virtualHosts."s3.${infra.domain}".extraConfig = 
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

        }
        {
            host = "s3-admin.${infra.domain}";
            port = 3903;
        }
    ];

in {
    config = 
                lib.mkMerge [
                    (reg.registerSecrets "garage" "garage" ["garage.service"] secrets)
                    (reg.registerEndpoints "garage" endpoints)];
}


