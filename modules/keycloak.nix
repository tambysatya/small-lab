{lib, inputs, infra, vmname, vmconf, pkgs, config, ...}:

let 
    reg = import ./infra-services/lib/register.nix {inherit lib inputs infra vmname;};
    secrets = {
        "keycloak-db.key" = {
            path ="/var/lib/keycloak/keycloak-db.key";
        };
    };
    servicevhost = "auth.${infra.domain}";
    serviceaddr = "127.0.0.1";
    serviceport = 8000;

in 

{
    config = lib.mkIf (builtins.elem "keycloak" vmconf.services)
                      (lib.mkMerge [
                        (reg.registerSecrets "keycloak" "root" ["keycloak.service"] secrets)
                        (reg.registerEndpoints "keycloak" [{host=servicevhost; port=serviceport;}])
                        {

                            services.keycloak = {
                              enable = true;

                              database = {
                                createLocally = true; #TODO
                                passwordFile = secrets."keycloak-db.key".path;
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
                        }
                      ]);
}
