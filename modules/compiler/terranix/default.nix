{inputs, lib, config, pkgs, infra, registry,...}:

    /*Generates a terranix configuration from the registry*/
let
    hostlib = import "${inputs.self.outPath}/lib/terranix/hosts.nix" {inherit lib inputs;};
    vmlib = import "${inputs.self.outPath}/lib/terranix/vms.nix" {inherit lib inputs infra registry;};
in {
config = lib.mkMerge [
        {
          terraform.required_providers.libvirt = {
            source = "dmacvicar/libvirt";
          };
        }
        (hostlib.generateHosts infra)
        (vmlib.generateVMDomains infra)
    ];
}
