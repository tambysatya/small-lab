{lib, inputs, config, ...}:

let
    utils = import ./lib.nix {inherit lib inputs;};
    allLetters = "bcdefghijklmnopqrstuvwxyz"; #starting from b since /dev/vda is reserved for the root file system;


    generatePartialMapping =
        env:
        dir@{mode, owner, path, reload, shared}:
        let
            diruid = utils.directory_id env path;
            info = config.infra.volumes.${diruid};
            disk = info.disk;
            vol = info.volume;
            mapping = {
                host=disk.path;
                inherit (disk) type mount;
                #letter is selected after nubbing the list of mappings
            };
            bind = {
                inherit (vol) owner reload mode;
            };
        in {};

in 
{
    imports = [./options];
    #infra.deploy.systems = processAllVolumes;
}
