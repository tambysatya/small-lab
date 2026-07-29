{inputs, infra, vmname, vmconf, config, lib, pkgs,...}:

let
    reg = import ../registry/lib/register.nix {inherit lib inputs infra vmname;};
    endpoints = [{
                   host = "nextcloud.${infra.domain}";
                   port = 80; 
                   is_http = false; #use port redirection instead of nginx + TLS
                 }];
in {

    config = lib.mkIf (builtins.elem "nextcloud" vmconf.services)
                (lib.mkMerge [ 
                    (reg.registerDBAccess "nextcloud" "nextcloud" 
                        {
                            role="nextcloud"; table="nextcloud"; serviceUnits=["nginx.service"];
                        })
                    (reg.registerS3Access "nextcloud" "nextcloud" 
                        {
                            bucket="nextcloud";
                            keyID=builtins.readFile "${inputs.self.outPath}/secrets/plain/tokens/nextcloud-s3-id.key";
                            serviceUnits = ["nginx.service"];

                        })
                    (reg.registerEndpoints "nextcloud" endpoints)]);
}

