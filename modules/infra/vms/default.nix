{lib, inputs, pkgs, config,...}:

let

    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};
    compileServiceRequirements = 
        vmname: srvname:
        let
            compileServiceRequirements' =
                srv@{users, endpoints, links, persistent, store,...}:
                {
                    inherit users endpoints links store persistent;
                };
        in compileServiceRequirements' config.infra.services.${srvname};

    /* Compilers implies to configure both the host and the container */
    compileContainerRequirements = 
        vmname: srvname:
        let compileContainerRequirements' = 
                srv@{users, endpoints, links, persistent, store,...}:
                {
                    inherit users;
                    containers.${srvname} = { #TODO persistent volumes...
                        inherit users endpoints links store persistent;
                    };
                };
        in compileContainerRequirements' config.infra.services.${srvname};

    compileRequirements = 
        vmname: vmconf:
        {
           requirements =
                utils.mergeAll  
                    (map (compileServiceRequirements vmname) vmconf.services
                    ++ map (compileContainerRequirements vmname) vmconf.containers);
        };


in {
    imports = [./options];
    infra.vms = lib.mapAttrs compileRequirements config.infra.topology.vms;
}
