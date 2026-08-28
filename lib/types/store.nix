{lib, inputs}:

/*
    Files moved into the store of a VM.
    Essentially external config files, encrypted passwords and ssl certificates
*/

let
    libtypes = lib.types;
    files = import ./files.nix {inherit lib inputs;};
    secrets = import ./secrets.nix {inherit lib inputs;};
    links = import ./links.nix {inherit lib inputs;};
    types = libtypes // files // secrets // links;

in
{
    store = types.submodule {
                options = {
                    plain = lib.mkOption {
                        description = "Unencrypted files, generated using openssl rand. Note that they are put in the nix store and are thus world-readable.";
                        type = types.listOf types.plaintext;
                        default = [];
                    };
                    passwords = lib.mkOption {
                        description = "Encrypted files, generated using openssl rand";
                        type = types.listOf types.password;
                        default = [];
                    };
                    sslCertificates = lib.mkOption {
                        description = "SSL certificates, generated and refreshed using SmallStep";
                        type = types.listOf types.sslCertificate;
                        default = [];
                    };

                };
        };
}
