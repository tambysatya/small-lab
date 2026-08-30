{lib, inputs, config, ...}:

let
    utils = import ./lib.nix {inherit lib inputs;};
    allLetters = "bcdefghijklmnopqrstuvwxyz"; #starting from b since /dev/vda is reserved for the root file system;
    allVolumes = config.infra.volumes;


    generateAsserts = 
        let processVolume =
                voluid:
                vol@{disk, volume, ...}:
                    [
                        {   # checks if shared properties match
                            assertion = disk.shared == volume.shared;
                            message = "Internal: ${voluid} mounted on ${disk.path}:${disk.mount} but disk.shared=${disk.shared} and volume.shared=${volume.shared}";
                        }
                        
                    ];
        in lib.mapAttrsToList processVolume allVolumes;

    allSharedVolumes = lib.filter ({volume, disk,...}:volume.shared) (builtins.attrValues allVolumes);
    envVM = env: if env.type == "vm" then env.host else env.host.vm;
    volumesByVM = lib.groupBy ({env,...}: envVM env) (builtins.attrValues allVolumes);
    sharedVolumesByVM = lib.groupBy ({env,...}: envVM env) allSharedVolumes;

    generateMapping =
        vmname: disks:
        let process = vol: letter:
                      {host = vol.disk.path; inherit letter;};
        in {
            ${vmname}.storage.mappings = 
                lib.zipListsWith process disks (lib.stringToCharacters allLetters);
        };

    generateBinds =
        vmname: disks:
        let process = vol@{serviceUID, disk, volume,...}:
                {
                    what = "${disk.mount}/${serviceUID}/${lib.removePrefix "/" volume.path}";
                    where = volume.path;
                    inherit (volume) owner reload mode;
                };
        in {
            ${vmname}.storage.binds =
                map process allSharedVolumes;
        };
    generateContainer = 
        vmname: disks:
        let
            containers = config.infra.topology.vms.${vmname}.containers;
            defaultMapping = serviceuid:
                {
                    ${vmname}.storage.containers.${serviceuid} = {
                        "/etc/resolv.conf" = {hostPath = "/etc/resolv.conf"; isReadOnly=true;};
                        "/var/lib/sops-nix/key.txt" = {hostPath = "/run/secrets/${serviceuid}.key"; isReadOnly=true;};
                    };
                };

            processDisk = vol@{serviceUID, disk, volume, env,...}:
                {
                    ${vmname}.storage.containers.${utils.envUID env}."${volume.path}" = {
                        hostPath = if volume.shared 
                                        then "${disk.mount}/${serviceUID}/${lib.removePrefix "/" volume.path}"
                                        else disk.mount;
                        isReadOnly = false;
                    };
                };
        in utils.mergeAll (map defaultMapping containers ++ map processDisk disks);
                
    processAllVolumes = 
        utils.mergeAll [
            (utils.mergeAll (lib.mapAttrsToList generateMapping volumesByVM) )
            (utils.mergeAll (lib.mapAttrsToList generateBinds sharedVolumesByVM))
            (utils.mergeAll (lib.mapAttrsToList generateContainer sharedVolumesByVM))
        ];

in 
{
    assertions = generateAsserts;
    imports = [./options];
    infra.deploy.systems = processAllVolumes;
}
