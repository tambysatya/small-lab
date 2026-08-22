{lib,inputs, ...}:

let
    types = lib.types // (import "${inputs.self.outPath}/lib/types" {inherit lib inputs;});
in
{
    files = lib.mkOption{
        description = "Various files and secrets exposed by the service. These files will be put in the nix store.";
        type = types.submodule {
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
    };
}
