{inputs, infra, vmname, vmconf, config, lib, pkgs,...}:

let
    reg = import ../registry/lib/register.nix {inherit lib inputs infra vmname;};
    infralib = import ../infra/lib.nix {inherit lib vmconf vmname;};

#    secrets = {
#        /* User passwords */
#        "nextcloud-db.key" = {
#            path = "/run/secrets/nextcloud-db.key";
#        };
#    };
    endpoints = [{
                   host = "postgres.${infra.domain}";
                   port = 5432; 
                   is_http = false; #use port redirection instead of nginx + TLS
                 }];
in {

    config = lib.mkIf (infralib.hostsService "postgres")
                (lib.mkMerge [ 
                    #(reg.registerSecrets "postgres" "postgres" ["postgres.service"] secrets)
                    (reg.registerCertificate "postgres" "postgres" ["postgres.service"] "postgres.${infra.domain}")
                    (reg.registerEndpoints "postgres" endpoints)]);
}

