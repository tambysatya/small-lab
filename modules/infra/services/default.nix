{lib, inputs, config,...}:

let
    utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};
    options = import ./options {inherit lib inputs;};

    computeHosts = 
        vmname: vmconf@{services, containers,...}:
            utils.mergeAll
                [(utils.mergeAll 
                    (map 
                        (service: 
                            {${service}.deployement = [{type = "vm"; host=vmname;}];})
                        services))
                 (utils.mergeAll
                    (map 
                        (service: 
                            {${service}.deployement = [{type="container"; host={container=service; vm=vmname;};}];})
                        containers))]; #containers names are equal to the service
in {
   options.infra.services = lib.mkOption {
        description = "Services resources";
        type = lib.types.attrsOf options.service;
   };
   config.infra.services = utils.mergeAll (lib.mapAttrsToList computeHosts config.infra.topology.vms);
}
