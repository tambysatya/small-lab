{lib, inputs, infra, vmname, vmconf, pkgs, config, ...}:

let 
    infralib = import "${inputs.self.outPath}/lib/infra" {inherit lib vmconf vmname;};
    reg = import "${inputs.self.outPath}/lib/registry/register.nix" {inherit inputs lib vmname infra vmconf;};

    servicevhost = "auth.${infra.domain}";
    serviceaddr = "127.0.0.1";
    serviceport = 8000;

in 
{
   config = 
                     (lib.mkMerge [
                         (reg.registerDBAccess "keycloak" 
                                {role = "keycloak"; table="keycloak"; reload= ["keycloak.service"]; owner="root";})
                         (reg.registerEndpoints "keycloak" [{host=servicevhost; port=serviceport;}])]);
}

