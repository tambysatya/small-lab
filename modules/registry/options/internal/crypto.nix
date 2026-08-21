{lib, inputs,...}:

let 
    types = lib.types;  
    secretType = types.enum ["plain" "password" "ldapssha" "sslCertificates" "postgres" "s3" "step-ca"];
    identityType = types.enum ["vm" "container"];

    vmIdentity = types.str;
    containerIdentity = types.submodule {
        options = {
            name = lib.mkOption {
                description = "Name of the container";
                type = types.str;
            };
            host = lib.mkOption {
                description = "Identity of the hosting vm";
                type = vmIdentity;
            };
        };
    };
    identityOwner = types.either vmIdentity containerIdentity;

    identity = types.submodule {
        options = {
            owner = lib.mkOption {
                description = "Cryptographic identity that can be recipient of a secret. Check identityType before processing.";
                type = types.identityOwner;
            };
            identityType = lib.mkOption {
                description = "Type of the owner of this identity. If this identity belongs to a container, it must be encrypted using the identity of the hosting vm";
                type = identityType;
            };
        };
    };

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
                type = types.listOf types.str;
            };
        };
    };

in {
    crypto = types.submodule {
        options = {
            identities = lib.mkOption {
                description = "Correspondance name => encryption method";
                type = types.attrsOf identity;
                default = {};
            };
            secrets = lib.mkOption {
                description = "Secrets with their recipients (mixed types).";
                type = types.listOf secret;
                default = [];
            };
        };
    };
}
