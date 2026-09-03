{flakeRoot, lib, inputs, pkgs, config, ...}:

let

in

{
    imports = [./options
               ./systems
               ./domains
              ];
    #infra.outputs = utils.mergeAll (lib.mapAttrsToList processSystem config.infra.deploy.systems);
}
