{lib, inputs, config, ...}:

let
    utils = import ./lib.nix {inherit lib inputs;};
    allLetters = lib.stringToCharacters "bcdefghijklmnopqrstuvwxyz"; #starting from b since /dev/vda is reserved for the root file system;

    
    generateMappings = 
        vmname: disks:
        let
            generateMapping = 
                host:
                {mount,type, ...}:
                letter: {
                    ${vmname}.storage.mappings = [{inherit host mount type letter;}];
                };
        in utils.mergeAll (lib.zipListsWith (f: x: f x) (lib.mapAttrsToList generateMapping disks) allLetters);

    generateBinds = 
        diruid:
        {env, path, bindTo, mode, owner, reload,...}:
        {
            ${utils.envHost env}.storage = {
                binds = if path != bindTo && env.type == "vm"
                        then [{what=path; where = bindTo; inherit mode owner reload;}]
                        else [];
                containers = if env.type == "container"
                             then {
                                    ${utils.envUID env}.${bindTo} = {hostPath=path; inherit mode owner reload;};
                                  }
                             else {};
            };
        };



in 
{
    imports = [./options];
    infra.deploy.systems = utils.mergeAll 
                                (lib.mapAttrsToList generateMappings config.infra.volumes.perVM
                                ++ lib.mapAttrsToList generateBinds config.infra.volumes.perDirectory);
}
