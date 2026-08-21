{lib, inputs, ...}:

let
    services = import ./services.nix {inherit lib;};
    vms = import ./vms.nix {inherit lib inputs;};
in
    services // vms
