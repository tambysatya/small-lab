{inputs, lib, config, pkgs, infra, registry, vmname,...}:

let
    utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};
    comp = import "${inputs.self.outPath}/lib/compiler" {inherit inputs lib pkgs infra registry vmname;};

    allUsers = 
        utils.mergeAll (lib.mapAttrsToList (_:sconf: sconf.users) registry.services);
in {
    imports = [
               ./options.nix
               ./base.nix
               ./native.nix
               ./nixos-container.nix
              ];    
    config.compiler.state = {
        users = allUsers; # TODO check if all IDs are differents
    };
}
