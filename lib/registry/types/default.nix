{lib, inputs, ...}:

let
    types = lib.types;
    registertypes = import ./register.nix {inherit inputs lib;};
    internaltypes = import ./internal {inherit inputs lib;};
in types // internaltypes // registertypes
