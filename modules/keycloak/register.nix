{lib, inputs, infra, vmname, vmconf, pkgs, config, ...}:

let 
    infralib = import ../infra/lib.nix {inherit lib vmconf vmname;};
    reg = import ../registry/lib/register.nix {inherit lib inputs infra vmname vmconf;};
    servicevhost = "auth.${infra.domain}";
    serviceaddr = "127.0.0.1";
    serviceport = 8000;

in 
{
   config = 
                     (lib.mkMerge [
                         (reg.registerDBAccess "keycloak" "root" 
                                {role = "keycloak"; table="keycloak"; serviceUnits = ["keycloak.service"];})
                         (reg.registerEndpoints "keycloak" [{host=servicevhost; port=serviceport;}])]);
}

