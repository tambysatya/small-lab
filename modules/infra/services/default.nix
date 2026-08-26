{lib, inputs, config,...}:

let
    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};

    computeHosts = 
        vmname: vmconf:
            let services = map (utils.serviceName config) vmconf.services;
            in
            utils.mergeAll
                [(utils.mergeAll 
                    (map 
                        (service: 
                            {${service}.deployements = [{type = "vm"; host=vmname;}];})
                        services))
                 (utils.mergeAll
                    (map 
                        (srvid: 
                            let service = utils.serviceName config srvid;
                            in {${service}.deployements = [{type="container"; host={container=srvid; vm=vmname;};}];})
                        vmconf.containers))]; #containers names are equal to the service
in {
   imports = [./options];
   config.infra.services = utils.mergeAll (lib.mapAttrsToList computeHosts config.infra.topology.vms);
}
