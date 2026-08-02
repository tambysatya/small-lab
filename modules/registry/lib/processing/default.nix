{lib, infra, registry, config, vmname, inputs,...}:
{
    imports = [
               ./baremetal.nix
               ./nixos-container.nix
              ];    
}
