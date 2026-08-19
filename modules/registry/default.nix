{lib, infra, config, inputs,...}:
let

    utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};
    infratypes = import "${inputs.self.outPath}/lib/infra/types.nix" {inherit lib;};
    modules = lib.map (name: "${inputs.self.outPath}/services/${name}/register.nix") infratypes.serviceNames;
    #modules = lib.map (name: "${inputs.self.outPath}/services/${name}/register.nix") (lib.unique (services ++ containers)); #enables only the services activated by the infra


    processDirs = 
        vmname: vmconf:
        servicename:
        let
           volumes = config.registry.services.${servicename}.volumes;
           #volumes = [ { mode = "0700"; owner = "nextcloud"; path = "/var/lib/nextcloud/config"; reload = [ "phpfmp.service" "nextcloud-setup.service" ]; } ];

           processDir = dir@{mode, owner, path, reload}:
                let
                   locations = lib.filter
                                    ({mapping,...}:
                                        builtins.elem path (map (builtins.getAttr "sys") mapping))
                                    (vmconf.persistentVolumes.qcows ++ vmconf.persistentVolumes.disks);
                   location = lib.head locations;
                   vollocation = (lib.head (lib.filter ({vol,sys}: sys == path) location.mapping)).vol;
                in
                assert (locations != []) || throw "Required persistent directory ${path} by ${servicename} not found on ${vmname}";
                assert (lib.length locations == 1) || throw "Persistent directory ${path} by ${servicename} found multiple times on ${vmname}";
                {
                    "${vmname}".persistentDirectories."${path}" = {
                       srcPath = "${location.mount.dir}/${lib.removePrefix "/" vollocation}";
                       inherit owner mode reload;
                    };
                };
            
        in lib.mkMerge (map processDir volumes);
    processQcow = 
        vmname: vmconf:
        qcow@{name, size, mount, mapping}:
        letter:
        let
           mntdir = mount.dir;
        in
        {
            ${vmname}.attachedVolumes."${mntdir}" = {
                hostDevice = "${vmname}_${name}.qcow";
                vmDevice = "vd${letter}";
                inherit (mount) options fsType;
                deviceType = "qcow";
            };
        };
    processDisk = 
        vmname: vmconf:
        disk@{src, mount, mapping}:
        letter:
        let mntdir = mount.dir;
        in {
            ${vmname}.attachedVolumes."${mntdir}" = {
                hostDevice = src;
                vmDevice = "sd${letter}";
                inherit (mount) options fsType;
                deviceType = "disk";
            };
        };
    processVolumes = 
        vmname: vmconf:
        let
        
        in lib.mkMerge [
            (lib.mkMerge 
                (lib.zipListsWith
                    (processQcow vmname vmconf)
                    (vmconf.persistentVolumes.qcows)
                    (lib.stringToCharacters "bcdefghijklmnopqrstuvwxyz")))
             (lib.mkMerge 
                (lib.zipListsWith
                    (processDisk vmname vmconf)
                    (vmconf.persistentVolumes.disks)
                    (lib.stringToCharacters "abcdefghijklmnopqrstuvwxyz")))
            ];

    compileVMsHosts = 
        vmname: vmconf:
            let 
                services = vmconf.services;
                containers = vmconf.containers;
            in lib.mkMerge [
                (lib.mkMerge
                   (lib.map (name: {"${name}".hosts.vms = [vmname];}) services))
                (lib.mkMerge 
                    (lib.map(name: {"${name}".hosts.containers = [vmname];}) containers))
            ];


    compileVMsFiles =
        vmname: vmconf:
            let 
                services = vmconf.services;
                containers = vmconf.containers;
            in lib.mkMerge [
                (lib.mkMerge 
                    (map (processDirs vmname vmconf) (vmconf.services ++ vmconf.containers)))
                (processVolumes vmname vmconf)

            ];


in 

{
imports = [./options.nix]++ modules;    
config.registry.services = lib.mkMerge (lib.mapAttrsToList compileVMsHosts infra.vms);
config.registry.vms = lib.mkMerge (lib.mapAttrsToList compileVMsFiles infra.vms);
}
