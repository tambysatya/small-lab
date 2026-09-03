{lib,inputs, config, ...}:

let 
    provider = 
        {
          terraform.required_providers.libvirt = {
            source = "dmacvicar/libvirt";
          };
        };


in {
    imports = [
        ./hosts.nix
        ./vms.nix
        ./volumes.nix
    ];
    infra.outputs.domains = provider;
}
