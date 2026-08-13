{lib,...}:

let
    types = lib.types;
    servicestypes = import ./services.nix {inherit lib;};
    vmtypes = import ./vms.nix {inherit lib;};
in types // servicestypes // vmtypes
