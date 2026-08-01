{lib, inputs, infra, registry, vmname, vmconf, pkgs, config, ...}:



let
    
    infralib = import ../infra/lib.nix {inherit lib vmconf vmname;};
    servicevhost = "auth.${infra.domain}";
    serviceaddr = "127.0.0.1";
    serviceport = 8000;
in {
    config = lib.mkIf (infralib.hostsService "keycloak")
        {

                services.keycloak = {
                  enable = true;
                  initialAdminPassword = builtins.readFile "${infra.secrets-path}/plain/keycloak-initial-admin";

                  database = {
                    passwordFile = registry.services."keycloak".secrets."keycloak-keycloak-db.key".path;
                    useSSL = true;
                    host = "postgres.${infra.domain}";
                    caCert = "/etc/intermediate_ca.crt";
                  };
                  settings = {
                    hostname = servicevhost;
                    http-host = serviceaddr;
                    http-port = serviceport;
                    proxy-headers = "xforwarded";
                    http-enabled = true;
                    truststore-paths = "/etc/root_ca.crt";
                    
                  };
                };
           };
}
