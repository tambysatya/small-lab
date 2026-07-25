{lib,...}:

let hostlib = import ./hosts.nix {inherit lib;};
    vmlib = import ./vms.nix {inherit lib;};
    generateConfig = infra:
      lib.mkMerge [
        {
          terraform.required_providers.libvirt = {
            source = "dmacvicar/libvirt";
          };
        }
        (hostlib.generateHosts infra)
        (vmlib.generateQcows infra)
        (vmlib.generateVMDomains infra)
      ];


in {

  # generates a terranix config based on an infrastructure
  # generator :: Infra -> Terranix
  generator = generateConfig;
}
