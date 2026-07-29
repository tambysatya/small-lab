{lib,...}:

let libtypes = lib.types;
    customtypes = import ../../../../lib/types.nix {inherit lib;};
    types = libtypes // customtypes;
in

{
    vmConfig = types.submodule {
        options = {
            dbAccess = {
                type = types.bool;
                default = false;
            };
        };
    };
}
    
