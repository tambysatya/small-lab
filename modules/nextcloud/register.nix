{inputs, infra, vmname, vmconf, config, lib, pkgs,...}:

let
    reg = import ../registry/lib/register.nix {inherit lib inputs infra vmname vmconf;};
    infralib = import ../infra/lib.nix {inherit lib vmconf vmname;};
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
                                keyID=builtins.readFile "${infra.secrets-path}/plain/tokens/nextcloud-s3-id.key"; #TODO maybe rename bc the name suggest that this value is sensitive
                                reload = ["phpfmp.service"];

                            })])
                    #(reg.registerEndpoints "nextcloud" endpoints)
                    #(reg.registerCertificate "nextcloud" "nginx" ["nginx.service"] "nextcloud.local.lphi.umontpellier.fr" )
                    ]);
}

