{lib, infra, registry, config, vmname, vmconf, inputs,...}:
let

    services = vmconf.services;
    containers = vmconf.containers;

    modules = lib.map (name: "${inputs.self.outPath}/services/${name}/register.nix") (lib.unique (services ++ containers));
 

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
