{lib, inputs, infra, vmname, vmconf, pkgs, config, ...}:

let 
    infralib = import ../infra/lib.nix {inherit lib vmconf vmname;};
    reg = import ../registry/lib/register.nix {inherit lib inputs infra vmname;};
    servicevhost = "auth.${infra.domain}";
    serviceaddr = "127.0.0.1";
    serviceport = 8000;

in 
{
   config = lib.mkIf (infralib.hostsService "keycloak")
                     (lib.mkMerge [
                         (reg.registerDBAccess "keycloak" "root" 
                                {role = "keycloak"; table="keycloak"; serviceUnits = ["keycloak.service"];})
                         (reg.registerEndpoints "keycloak" [{host=servicevhost; port=serviceport;}])]);
}

