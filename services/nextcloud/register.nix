{inputs, config, lib, pkgs,...}:

let
 
    infra = config.infra;
    reg = import "${inputs.self.outPath}/lib/registry/register.nix" {inherit inputs lib infra;};
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
    secret = {names = ["nextcloud-admin.key"]; owner="nextcloud"; reload=["phpfmp.service"]; kind = {provider="openssl";};};
in {

    config.registry = 
                (lib.mkMerge [ 
                    (lib.mkMerge [
                        (reg.registerSecret "nextcloud" "nextcloud-keys" 
                            {
                                names = ["nextcloud-admin.key"];
                                owner="nextcloud";
                                reload = ["phpfmp.service"];
                                kind = {provider="openssl";};
                            })
                        (reg.registerDBAccess "nextcloud" 
                            {
                                owner="nextcloud"; role="nextcloud"; table="nextcloud"; reload=["phpfmp.service" "nextcloud-setup.service"];
                            })
                        (reg.registerS3Access "nextcloud" 
                            {
                                owner = "nextcloud";
                                bucket="nextcloud";
                                reload = ["phpfmp.service"];

                            })])
                    (reg.registerEndpoints "nextcloud" endpoints)
                    (reg.registerVolume "nextcloud" {owner="nextcloud"; path="/var/lib/nextcloud/config"; reload=["phpfmp.service" "nextcloud-setup.service"];})
                    (reg.registerUser "nextcloud" "nextcloud" 10003)
                    ]);
}

