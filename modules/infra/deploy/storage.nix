{lib, inputs, config, ...}:

let
    utils = import ./lib.nix {inherit lib inputs;};
    allLetters = "bcdefghijklmnopqrstuvwxyz"; #starting from b since /dev/vda is reserved for the root file system;
    allVolumes = config.infra.volumes;
    envVM = env: if env.type == "vm" then env.host else env.host.vm;
    volumesByVM = lib.groupBy ({env,...}: envVM env) (builtins.attrValues allVolumes);

    generateMapping =
        vmname: disks:
        let process = vol: letter:
                      {host = vol.disk.path; inherit letter;};
        in {
            ${vmname}.storage.mappings = 
                lib.zipListsWith process disks (lib.stringToCharacters allLetters);
        };


    processAllVolumes = 
        utils.mergeAll [
            (utils.mergeAll (lib.mapAttrsToList generateMapping volumesByVM) )
        ];

in 
{
    imports = [./options];
    infra.deploy.systems = processAllVolumes;
}
