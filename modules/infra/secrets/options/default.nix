{lib, inputs, ...}:
let
    types = lib.types // (import "${inputs.self.outPath}/lib/types" {inherit lib inputs;});
    secretType = types.enum ["plain" "password" "ldapssha" "sslCertificates" "postgres" "s3" "step-ca" "age"];

    secret = types.submodule {
        options = {
            type = lib.mkOption {
                description = "Type of the secret";
                type = secretType;
            };
            content = lib.mkOption {
                description = "Content of the secret. Must match the type";
                type = with types;
                        #nullOr (oneOf [plaintext password sslCertificate postgresAccess s3Access ldapSSHA]);
                        nullOr attrs; #TODO
            };
            recipients = lib.mkOption {
                description = "Identity names of the recipients.";
                type = types.listOf types.deployementEnvironment;
            };
        };
    };

in 

{
    options.infra.secrets = lib.mkOption {
        description = "Summary of the secrets dispatched across the infrastructure. Useful for automatic secret generations.";
        type = types.submodule {
            options = {
                allEnvs = lib.mkOption {
                    description = "List of unique identifiers";
                    type = types.listOf types.deployementEnvironment;
                };
                allSecrets = lib.mkOption {
                    description = "Summary of the secrets dispatched across the infrastructure. Useful for automatic secret generations.";
                    type = types.listOf secret;
                };
            };
        };
    };

}
