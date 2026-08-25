{lib, inputs,...}:
let
    types = lib.types;
in
{

    persistentDirectory = types.submodule { # Persistent volumes
        options = {
            owner = lib.mkOption {
                description = "Owner of the directory";
                type = types.str;
                default = "root";
            };
            path = lib.mkOption {
                description = "Path of the persistent directory";
                type = types.str;
                example = "/var/lib/docker/storage";
            };
            reload = lib.mkOption {
                description = "Services that requires the volume.";
                type = types.listOf types.str;
                default = [];
            };
            mode = lib.mkOption {
                description = "Permissions of the directory";
                type = types.str;
                default = "0700";
            };
        };
    };
}
