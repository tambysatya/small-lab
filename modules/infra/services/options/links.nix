{lib,inputs, ...}:

let
    types = lib.types // (import "${inputs.self.outPath}/lib/types" {inherit lib inputs;});
in

{
    links = types.submodule{
        options = {
            postgres = lib.mkOption {
                description = "PostgresSQL access";
                type = types.listOf types.postgresAccess;
                default = [];
            };
            s3 = lib.mkOption {
                description = "S3 buckets";
                type = types.listOf types.s3access;
                default = [];
            };
            ldapSSHAs = lib.mkOption {
                description = "Hashed LDAP passwords";
                type = types.listOf types.ldapSSHA;
                default = [];
            };
        };
    };


}

