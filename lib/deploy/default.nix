{lib,...}:

let hostlib = import ./hosts.nix {inherit lib;};
    vmlib = import ./vms.nix {inherit lib;};
    utils = import ../utils.nix {inherit lib;};
    generateConfig = infra:
      lib.foldl' utils.merge {} [
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
  generateConfig = generateConfig;
}
