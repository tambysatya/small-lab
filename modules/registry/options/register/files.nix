{lib,inputs, ...}:

let
    types = lib.types // (import "${inputs.self.outPath}/lib/registry/types" {inherit lib inputs;});
in
{
    files = lib.mkOption{
        description = "Various files and secrets exposed by the service";
        type = types.submodule {
            options = {
                plaintexts = lib.mkOption {
                    description = "Unencrypted files, generated using openssl rand";
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
                s3Accesses = lib.mkOption {
                    description = "S3 buckets";
                    type = types.listOf types.s3access;
                    default = [];
                };
                postgresAccesses = lib.mkOption {
                    description = "PostgresSQL access";
                    type = types.listOf types.postgresAccess;
                    default = [];
                };
                ldapSSHAs = lib.mkOption {
                    description = "Hashed LDAP passwords";
                    type = types.listOf types.ldapSSHA;
                    default = [];
                };
            };
        };
    };
}
