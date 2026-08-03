{inputs, infra, vmname, vmconf, config, lib, pkgs,...}:

let
    reg = import ../registry/lib/register.nix {inherit lib inputs infra vmname vmconf;};
    infralib = import ../infra/lib.nix {inherit lib vmconf vmname;};
    endpoints = [{
                   host = "nextcloud.${infra.domain}";
                   port = 80; 
                   is_http = true; #use port redirection instead of nginx + TLS
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
                    (reg.registerEndpoints "nextcloud" endpoints)]);
}

