{lib, inputs, pkgs, config, path, ...}:

let

    utils = import ../deploy/lib.nix {inherit inputs lib;};

    mkUser = {name, uid}:
        {
            users.${name} = {
               inherit uid;
               group = name;
               isSystemUser = true;
            };
            groups.${name} = {
                gid = uid;
            };
        };
    processUsers = 
        name: deploy:
        {
            config.users = utils.mergeAll (map mkUser deploy.users);
        };
in

{
    imports = [./options
               ./step.nix
               ./volumes.nix
               ./network.nix
              ];
    #infra.outputs = utils.mergeAll (lib.mapAttrsToList processSystem config.infra.deploy.systems);
    infra.outputs = lib.mapAttrs processUsers config.infra.deploy.systems;
}
