{lib, inputs,...}:

let 
    types = lib.types;  
    recipients = lib.mkOption {
        description = "List of key names to encrypt this secret. If set to [], the secret will be stored in plain text";
        type = types.listOf types.str;
    };
    password = types.submodule {
        options = {
            filename = lib.mkOption {
                description = "Name of the password";
                type = types.str;
            };
            size = lib.mkOption {
                type = types.ints.positive;
                default = 64;
            };
            type = lib.mkOption {
                type = types.enum ["base64" "hex"];
                default = "base64";
            };
            inherit recipients;
        };
    };
    certificate = types.submodule {
        options = {
            dns = lib.mkOption {
                description = "Domain name that is claim";
                example = "auth.local.fr";
            };
            inherit recipients;
        };
    };

in {
    secrets = types.submodule {
        ca = lib.mkOption {
            description = "Age key of the Certificate authority";
            example = ".secrets/age/identity.key";
            type = types.str;
        };
        passwords = lib.mkOptions {
            description = "Secrets generated using openssl rand";
            type = types.listOf password;
        };
        certificates = lib.mkOption {
            description = "TLS certificates generated using step-cli";
            type = types.listOf certificate;
        };
    };
}
