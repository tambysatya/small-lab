{lib, inputs, config,...}:

let
    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};

    computeHosts = 
        vmname: vmconf@{services, containers,...}:
            utils.mergeAll
                [(utils.mergeAll 
                    (map 
                        (service: 
                            {${service}.deployements = [{type = "vm"; host=vmname;}];})
                        services))
                 (utils.mergeAll
                    (map 
                        (service: 
                            {${service}.deployements = [{type="container"; host={container=service; vm=vmname;};}];})
                        containers))]; #containers names are equal to the service
in {
   imports = [./options];
   config.infra.services = utils.mergeAll (lib.mapAttrsToList computeHosts config.infra.topology.vms);
}
