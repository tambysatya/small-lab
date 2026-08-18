{lib, infra, registry, config, vmname, inputs,...}:
{
    imports = [
               ./options.nix
               ./native.nix
               ./nixos-container.nix
              ];    
}
