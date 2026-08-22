{lib, inputs,...}:

let 
    libtypes = lib.types;
    filestypes = import ./files.nix {inherit lib inputs;};
    networktypes = import ./network.nix {inherit lib inputs;};
    types = libtypes // filestypes // networktypes;
in  with types; 
rec {

    opensslSize = lib.mkOption {
        description = "Length of the string to be generated using openssl rand";
        type = types.ints.positive;
        default = 64;
    };
    opensslType = lib.mkOption {
        description = "Type of the string to be generated using openssl rand";
        type = types.enum ["base64" "hex"];
    };
    plaintext = types.submodule { #will be world readable
            options = {
                inherit filename opensslSize opensslType;
            };
    };
    password = types.submodule {
            options = {
                inherit filename owner reload opensslSize opensslType;
            };
    };
    sslCertificate = types.submodule {
            options = {
                inherit hostname owner reload;
            };
    };



}
