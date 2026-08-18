{lib, infra, registry, config, vmname, vmconf, inputs,...}:
let

    infratypes = import "${inputs.self.outPath}/lib/infra/types.nix" {inherit lib;};
    services = vmconf.services;
    containers = vmconf.containers;
    modules = lib.map (name: "${inputs.self.outPath}/services/${name}/register.nix") infratypes.serviceNames;
    #modules = lib.map (name: "${inputs.self.outPath}/services/${name}/register.nix") (lib.unique (services ++ containers)); #enables only the services activated by the infra
 

in 

{
imports = [./options.nix] ++ modules;    
config = lib.mkMerge [
            (lib.mkMerge
                (lib.map (name: {registry.services."${name}".hosts.vms = [vmname];}) services))
            (lib.mkMerge 
                (lib.map(name: {registry.services."${name}".hosts.containers = [vmname];}) containers))
            ];
}
