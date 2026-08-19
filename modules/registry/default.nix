{lib, infra, config, inputs,...}:
let

    utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};
    infratypes = import "${inputs.self.outPath}/lib/infra/types.nix" {inherit lib;};
    modules = lib.map (name: "${inputs.self.outPath}/services/${name}/register.nix") infratypes.serviceNames;
    #modules = lib.map (name: "${inputs.self.outPath}/services/${name}/register.nix") (lib.unique (services ++ containers)); #enables only the services activated by the infra

    compileVMs =
        vmname: vmconf:
            let 
                services = vmconf.services;
                containers = vmconf.containers;
            in lib.mkMerge [
                (lib.mkMerge
                    (lib.map (name: {registry.services."${name}".hosts.vms = [vmname];}) services))
                (lib.mkMerge 
                    (lib.map(name: {registry.services."${name}".hosts.containers = [vmname];}) containers))
            ];


in 

{
imports = [./options.nix] ++ modules;    
config = lib.mkMerge (lib.mapAttrsToList compileVMs infra.vms);
}
