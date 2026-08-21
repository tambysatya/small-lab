{inputs, config, lib, pkgs,...}:

let

    infra = config.infra;
    reg = import "${inputs.self.outPath}/lib/registry/register.nix" {inherit inputs lib infra;};

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

/*
    config.registry = 
                (lib.mkMerge [ 
                    #(reg.registerSecrets "postgres" "postgres" ["postgres.service"] secrets)
                    (reg.registerCertificate "postgres" "postgres" ["postgresql.service"] "postgres.${infra.domain}")
                    (reg.registerEndpoints "postgres" endpoints)
                    (reg.registerUser "postgres" "postgres" 10005)
                ]);
*/
}

