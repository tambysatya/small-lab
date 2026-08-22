{lib,inputs,...}:

let
    libtypes = lib.types;
    types = libtypes;
in {

    hostname = lib.mkOption {
        description = "Host domain";
        type = types.str;
        example = "auth.local.fr";
    };

    
}
