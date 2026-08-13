{lib, inputs, ...}:

let
    types = lib.types;
    servicestypes = import ./services.nix {inherit inputs lib;};
    vmtypes = import ./vms.nix {inherit inputs lib;};
    registertypes = import ./register.nix {inherit inputs lib;};
in types // servicestypes // vmtypes // registertypes
