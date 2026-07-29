{lib,...}:

let libtypes = lib.types;
    customtypes = import ../../../../lib/types.nix {inherit lib;};
    types = libtypes // customtypes;
    infratypes = import ../../../infra/types.nix {inherit lib;};
in

{
    vmConfig = types.submodule {
        options = {
            use-db = lib.mkOption {
                type = types.listOf infratypes.serviceType;
                default = [];
                description = "List of services requesting a POSTGRESQL access";
            };
            use-s3 = lib.mkOption {
                type = types.listOf infratypes.serviceType;
                default = [];
                description = "List of services requesting a S3 access";
            };
        };
    };
}
    
