{lib, inputs, config, pkgs,...}:
let
    utils = import ./lib {inherit lib inputs;};
    generateFileSystem = 
        vmname: deploy:
        let genFS = {letter, mount,fs,...}: {
                            ${mount} = {
                                fsType = fs;
                                device = "/dev/vd${letter}";
                            };
                    };
        {
            config = {
                fileSystems = utils.mergeAll (map genFS deploy.mappings); 
            };
        };
in{
    config.infra.outputs = lib.mapAttrs generateFileSystem config.infra.deploy.systems;
}
