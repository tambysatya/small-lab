{flakeRoot, lib, inputs, config, pkgs,...}:
let
    utils = import ./lib {inherit lib inputs flakeRoot;};
    initDir = 
        {path, mode, owner,...}: 
        ''
            if [[ ! -d ${path} ]]; then
                mkdir -p ${path}
                chown ${owner} ${path}
                chmod ${mode} ${path}
            fi
        '';
    
    mkInitDirServices = ensuredirs:
        let reload = lib.unique (map (builtins.getAttr "reload") ensuredirs);
            script = lib.concatMapStringsSep "\n" initDir ensuredirs;
            mntservices = lib.unique (map ({mount,...}: utils.pathToMountUnit mount) ensuredirs);
        in {
            "init-persistent-dirs" = {
                description = "Ensures that bind-mounted and container-mounted directories exist";
                before = reload;
                requiredBy = reload;
                after = mntservices;
                requires = mntservices;
                serviceConfig.Type = "oneshot";
                inherit script;
            };
        };

    generateFileSystem = 
        vmname: deploy:
        let 
            /*
            genFS = {letter, mount,fs,options,...}: {
                            ${mount} = {
                                fsType = fs;
                                device = "/dev/vd${letter}";
                                inherit options;
                            };
                    };
            */
            genDisko = {letter, mount, options, fs,...}:{
                "vd${letter}" ={
                    device = "/dev/vd${letter}";
                    type = "disk";
                    content = {
                        type = "filesystem";
                        format = fs;
                        mountpoint = mount;
                        mountOptions = options;
                    };
                };
            };
            genMountService  = 
                bind@{reload, ...}: 
                {
                    inherit (bind) what where;
                    before = reload;
                    requiredBy = reload;
                    options = "bind";
                    type = "none";
                };           

            #fileSystems = utils.mergeAll (map genFS deploy.storage.mappings);
            env = deploy.env;
        in {
            ${vmname}.config = {
                #fileSystems = fileSystems;
                imports = [inputs.disko.nixosModules.disko];
                disko.devices.disk = utils.mergeAll (map genDisko deploy.storage.mappings);
                systemd.mounts = map genMountService deploy.storage.binds;
                systemd.services = mkInitDirServices deploy.storage.ensureDirs;
            };
        };
in{
    config.infra.outputs = utils.mergeAll (lib.mapAttrsToList generateFileSystem config.infra.deploy.systems);
}
