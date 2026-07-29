{lib, inputs, infra, vmname, vmconf, pkgs, config, ...}:

let 
    reg = import ../registry/lib/register.nix {inherit lib inputs infra vmname;};
    servicevhost = "auth.${infra.domain}";
    serviceaddr = "127.0.0.1";
    serviceport = 8000;

in 
{
   config = lib.mkIf (builtins.elem "keycloak" vmconf.services)
                     (lib.mkMerge [
                         (reg.registerDBAccess "keycloak" {role = "keycloak"; table="keycloak"; serviceUnits = ["keycloak.service"];})
                         (reg.registerEndpoints "keycloak" [{host=servicevhost; port=serviceport;}])]);
}

