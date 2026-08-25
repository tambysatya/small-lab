{lib, inputs, pkgs, config,...}:

let

    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};
    compileService = 
        vmname: srvname:
        let
            compileService' =
                srv@{users, endpoints, links, persistent, store,...}:
                {
                    vms.${vmname}.users = users;
                };
        in compileService' config.infra.services.${srvname};

    /* Compilers implies to configure both the host and the container */
    compileContainer= 
        vmname: srvname:
        let compileContainer' = 
                srv@{users, endpoints, links, persistent, store,...}:
                {
                    vms.${vmname} = {inherit users;};
                    containers.${utils.container_id vmname srvname}= { 
                        inherit users;
                    };
                };
        in compileContainer' config.infra.services.${srvname};

    compileVM = 
        vmname: vmconf:
            utils.mergeAll [
                (utils.mergeAll (map (compileContainer vmname) vmconf.containers))
                (utils.mergeAll (map (compileService vmname) vmconf.services))
                ];



in {
    imports = [./options ./sops.nix];
    infra.deploy = utils.mergeAll 
                        (lib.mapAttrsToList compileVM config.infra.topology.vms);
}
