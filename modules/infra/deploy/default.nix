{lib, inputs, pkgs, config,...}:

let

    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};


    processVM =
        vmname: {ip, services, containers, ...}:
        let
            mkEnv = name: {type="container"; host={container=name; vm=vmname;};};
            ctconfs = lib.imap 
                        (i: name: {
                            ${utils.envUID (mkEnv name)} = {
                                ip = "192.168.100.${lib.toString (50+i)}";
                                env = mkEnv name;
                            };
                        })
                        containers;
            vmconf = {
                        ${vmname} = {
                            env = {type="vm"; host=vmname;};
                            inherit ip;
                        };
                     };
        in utils.mergeAll ([vmconf]  ++ ctconfs);

in {
    imports = [./options
               ./store.nix
               #./links.nix 
               #./storage.nix
               #./endpoints.nix
               ];
    #imports = [./options ./store.nix ./links.nix ./endpoints.nix];
    infra.deploy.systems = utils.mergeAll (lib.mapAttrsToList processVM config.infra.topology.vms);
}
