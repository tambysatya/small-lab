{inputs, infra, vmname, vmconf, config, lib, pkgs,...}:

let

    infralib = import "${inputs.self.outPath}/lib/infra" {inherit lib vmconf vmname;};
    reg = import "${inputs.self.outPath}/lib/registry/register.nix" {inherit inputs lib vmname infra vmconf;};
    host = "nextcloud.${infra.domain}";
    endpoints = [{
                   host = host;
                   port = 80; 
                   is_http = true; #use port redirection instead of nginx + TLS
                   extraNginxConfig = {
                        virtualHosts.${host}.extraConfig = 
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
                 }];
in {

    config = 
                (lib.mkMerge [ 
                    (lib.mkMerge [
                        (reg.registerSecrets "nextcloud" "nextcloud" ["phpfmp.service"] 
                            {
                                "nextcloud-admin.key"={owner="nextcloud";};
                            })
                        (reg.registerDBAccess "nextcloud" 
                            {
                                owner="nextcloud"; role="nextcloud"; table="nextcloud"; reload=["phpfmp.service"];
                            })
                        (reg.registerS3Access "nextcloud" 
                            {
                                owner = "nextcloud";
                                bucket="nextcloud";
                                reload = ["phpfmp.service"];

                            })])
                    (reg.registerEndpoints "nextcloud" endpoints)
                    ]);
}

