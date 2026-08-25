{lib, inputs, pkgs, config,...}:

let

    utils = import "${inputs.self.outPath}/lib";
    processService =
        vmname:
        srvname:
        let
            processService' =
                srv@{users, endpoints, links, persistent, store,...}:
                {
                    ${vmname} = {
                        inherit users endpoints links store;
                    };
                };
        in {};

        

in {
    imports = [./options];
    config.infra.vms = l
}
