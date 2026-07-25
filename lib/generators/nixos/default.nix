{lib,...}:

{

  # Generates a NixOS configuration
  # generator : Infra -> NixOS

  generator = import ./vm.nix {inherit lib;}.generateVMs;

}
