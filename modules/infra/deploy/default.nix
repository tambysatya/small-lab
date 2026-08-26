{lib, inputs, pkgs, config,...}:

let

    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};
    compileService = 
        vmname: srvname:
        let
            compileService' =
                srv@{users, endpoints, links, persistent, store,...}:
                {
                    systems.${vmname}.users = users;
                };
        in compileService' config.infra.services.${utils.serviceName config srvname};

    /* Compilers implies to configure both the host and the container */
    compileContainer= 
        vmname: srvname:
        let compileContainer' = 
                srv@{users, endpoints, links, persistent, store,...}:
                {
                    systems.${vmname} = {inherit users;};
                    systems.${utils.container_id vmname srvname}= { 
                        inherit users;
                        provisioner = "container";
                    };
                };
        in compileContainer' config.infra.services.${utils.serviceName config srvname};

    compileVM = 
        vmname: vmconf:
            utils.mergeAll [
                {systems.${vmname}.provisioner = "vm";}
                (utils.mergeAll (map (compileContainer vmname) vmconf.containers))
                (utils.mergeAll (map (compileService vmname) vmconf.services))
                ];



in {
    imports = [./options ./store.nix];
    infra.deploy = utils.mergeAll (lib.mapAttrsToList compileVM config.infra.topology.vms);
}
