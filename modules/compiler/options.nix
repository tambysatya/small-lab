{config,lib,...}:

let
    types = lib.types;
    compilerOptions = types.submodule {
        options = {
            noEndpoints = lib.mkOption {
                description = "Do not compiles endpoints";
                type = types.bool;
                default = false;
            };
            noBindMounts = lib.mkOption {
                description = "Do not bind-mount the volumes";
                type = types.bool;
                default = false;
            };
        };
    };

    compilerState = types.submodule {
        options = {
            users = lib.mkOption {
                description = "UserIDs mappings";
                type = types.attrsOf types.int;
                default = {};
            };
        };
    };
in {
    options = {
        compiler = {
            options = lib.mkOption {
                type = compilerOptions;
            };
            state = lib.mkOption {
                description = "Desired state of the infrastructure. Need to be checked prior to any migration";
                type = compilerState;
            };
        };
    };
}
