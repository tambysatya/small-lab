{lib, inputs, ...}:
let
    types = lib.types // (import "${inputs.self.outPath}/lib/types" {inherit lib inputs;});
    secretType = types.enum ["plain" "password" "ldapssha" "sslCertificates" "postgres" "s3" "step-ca"];
    secret = types.submodule {
        options = {
            type = lib.mkOption {
                description = "Type of the secret";
                type = secretType;
            };
            content = lib.mkOption {
                description = "Content of the secret. Must match the type";
                type = types.attrs;
            };
            recipients = lib.mkOption {
                description = "Identity names of the recipients.";
                type = types.listOf types.deployementHost;
            };
        };
    };

in 

{
    options.infra.secrets = lib.mkOption {
        description = "Summary of the secrets dispatched across the infrastructure. Useful for automatic secret generations.";
        type = types.listOf secret;
    };

}
