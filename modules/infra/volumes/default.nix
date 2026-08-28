{lib, inputs, config, ...}:

let
    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};
    mkServiceEnv =
        vmname: srvuid:
        let infos = config.infra.topology.services.${srvuid};
            vmconf = config.infra.topology.vms.${vmname};
        in if builtins.elem srvuid vmconf.services
            then {type="vm"; host="vm"; inherit (infos) priority tags;}
            else {type="container"; host={vm=vmname; container=srvuid;}; inherit (infos) priority tags;};

    mountpoint = 
        disk@{path, mount,...}:
        if mount != null
            then mount
            else "/srv/${builtins.baseNameOf path}";
    findDisk = # search the disk containing the path
        path: vmname: shared:
        let vmconf = config.infra.topology.vms.${vmname};
            disks = vmconf.disks;
            sharedDisks = lib.filter (builtins.getAttr "shared") disks;
            containsPath = lib.filter (disk: path == mountpoint(disk)) disks;
        in
        assert ((containsPath != []) || (shared && (sharedDisks != []))) || throw "volume ${path} cannot be stored in ${vmname}. Enable sharing on a disk or explicitely create a disk mounted on this path";
        if containsPath != [] then containsPath
            else if shared then sharedDisks
            else [];


    processService = 
        vmname: vmconf:
        srvuid:
        let srv = utils.serviceInfo config srvuid;
            volumes = srv.persistent;
            processVolume =
                vol@{path,shared, ...}:
                {
                    ${utils.directory_id srvuid path} = 
                    {
                        volume = vol;
                        disk = lib.head (findDisk path vmname shared);
                        serviceUID = srvuid;
                        env= mkServiceEnv vmname srvuid;
                    };
                };
        in utils.mergeAll (map processVolume volumes);
    processVM =
        vmname: vmconf@{services, containers,...}:
        let
        in utils.mergeAll 
                (map (processService vmname vmconf) (services ++ containers));

in {
    imports = [./options];
    config.infra.volumes =
        utils.mergeAll (lib.mapAttrsToList processVM config.infra.topology.vms);
}
