{lib,...}:

{

  # Generates a NixOS configuration
  # generator : Infra -> NixOS

  generator = import ./vms.nix {inherit lib;}.generateVMs;

}
