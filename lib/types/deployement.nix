{lib, inputs,...}:
let
    types = lib.types;
    vmname = types.str;
in rec {
    deployementOptions = types.submodule {
        options = {
            priority = lib.mkOption {
                description = "Priority of the service";
                type = types.enum ["primary" "fallback" "test"]; #TODO check if there is only one primary across the infrastructure
                default = "primary";
            };
        };
    };


    container = types.submodule  {
        options = {
            name = lib.mkOption {
                description = "Name of the container";
                type = types.str;
            };
            vm = lib.mkOption {
                description = "Name of the hosting virtual machine";
                type = types.str; # TODO check if exists
            };
        };
    };
    deployementEnvironmentType = types.enum ["vm" "container"];
    deployementEnvironment = types.either vmname container;

    deployement = types.submodule {
        options = {
            type = lib.mkOption {
                description = "Type of deployement: container or nixos";
                type = deployementEnvironmentType;
            };
            env = lib.mkOption {
                description = "Which environment hosts the service";
                type = deployementEnvironment;
            };
            options = lib.mkOption{
                description = "Configuration of the deployement (priority...)";
                type = deployementOptions;
            };
        };
    };

}
