{lib, inputs, ...}:
let
    libtypes = lib.types;
    filestypes = import ./files.nix {inherit lib inputs;};
    secrets = import ./secrets.nix {inherit lib inputs;};
    types = libtypes // filestypes // secrets;
in
with types;
rec {

    s3access = types.submodule {
            options = {
                inherit owner reload;
                bucket = lib.mkOption{
                    description = "Name of the bucket";
                    type = types.str;
                    example = "nextcloud-bucket";
                };
            };
    };
    postgresAccess = types.submodule {
            options = {
                inherit owner reload;
                database = lib.mkOption {
                    description = "Name of the database. So far, the role (= user) name does necessarily match the database"; #TODO
                    type = types.str;
                    example = "nextcloud";
                };
            };
    };
    ldapSSHA = types.submodule {
            options = {
                inherit filename owner reload opensslSize opensslType;
            };
    };
    links = types.submodule{
        options = {
            postgres = lib.mkOption {
                description = "PostgresSQL access";
                type = types.listOf postgresAccess;
                default = [];
            };
            s3 = lib.mkOption {
                description = "S3 buckets";
                type = types.listOf s3access;
                default = [];
            };
            ldap = lib.mkOption {
                description = "Hashed LDAP passwords";
                type = types.listOf ldapSSHA;
                default = [];
            };
        };
    };


}
