{inputs, config, lib, pkgs,...}:

let

    infra = config.infra;
    hostname = "postgres.${infra.domain}";
    owner = "postgres";
    reload = ["postgresql.service"];
in {

registry.services.postgres = {
    users = [{name = "postgres"; uid=10005;}];
    files.sslCertificates = [
        {inherit hostname owner reload;}
    ];
    endpoints.tcp = [
        {inherit hostname; port = 5432;}
    ];
    persistent = [
        {path = "/var/lib/postgresql"; inherit owner reload;}
    ];
};

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

