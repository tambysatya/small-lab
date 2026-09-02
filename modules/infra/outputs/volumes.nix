{lib, inputs, config, pkgs,...}:
let
    utils = import ./lib {inherit lib inputs;};
    initDir = 
        path: mode: owner: 
        ''
            if [[ ! -d ${path} ]]; then
                mkdir -p ${path}
                chown ${owner} ${path}
                chmod ${mode} ${path}
            fi
        '';
    allContainerFile =
        ctinfo: map (builtins.getAttr "hostPath") (builtins.attrValues ctinfo);
    allContainersFile =
        deploy: lib.concatMap allContainerFile (builtins.attrValues deploy.storage.containers);
    generateFileSystem = 
        vmname: deploy:
        let allBoundFiles = map (builtins.getAttr "hostPath") deploy.storage.binds;
            allFiles = allContainerFile deploy ++ allBoundFiles;
            genFS = {letter, mount,fs,...}: {
                            ${mount} = {
                                fsType = fs;
                                device = "/dev/vd${letter}";
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

            fileSystems = utils.mergeAll (map genFS deploy.storage.mappings);
            env = deploy.env;
        in {
            ${vmname}.config = {
                fileSystems = utils.mergeAll (map genFS deploy.storage.mappings); 
                systemd.mounts = map genMountService deploy.storage.binds;
            };
        };
in{
    config.infra.outputs = utils.mergeAll (lib.mapAttrsToList generateFileSystem config.infra.deploy.systems);
}
