{lib,inputs,...}:

let hostlib = import ./hosts.nix {inherit lib inputs;};
    vmlib = import ./vms.nix {inherit lib inputs;};
    generateConfig = infra:
      lib.mkMerge [
        {
          terraform.required_providers.libvirt = {
            source = "dmacvicar/libvirt";
          };
        }
        (hostlib.generateHosts infra)
        (vmlib.generateRootQcows infra)
        (vmlib.generateVMDomains infra)
      ];


in {

  # generates a terranix config based on an infrastructure
  # generator :: Infra -> Terranix
  generator = generateConfig;
}
