{lib, inputs, ...}:
let
    libtypes = lib.types;
    filestypes = import ./files.nix {inherit lib inputs;};
    secrets = import ./secrets.nix {inherit lib inputs;};
    types = libtypes // filestypes // secrets;
in
with types;
{

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
                inherit filename owner opensslSize opensslType;
            };
    };
}
