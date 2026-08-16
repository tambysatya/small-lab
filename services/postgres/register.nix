{inputs, infra, vmname, vmconf, config, lib, pkgs,...}:

let

    infralib = import "${inputs.self.outPath}/lib/infra" {inherit lib vmconf vmname;};
    reg = import "${inputs.self.outPath}/lib/registry/register.nix" {inherit inputs lib vmname infra vmconf;};

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

    config = 
                (lib.mkMerge [ 
                    #(reg.registerSecrets "postgres" "postgres" ["postgres.service"] secrets)
                    (reg.registerCertificate "postgres" "postgres" ["postgresql.service"] "postgres.${infra.domain}")
                    (reg.registerEndpoints "postgres" endpoints)]);
}

