{lib, inputs, config,...}:

let
    libtypes = import "${inputs.self.outPath}/lib/types" {inherit lib inputs;};
    types = lib.types // libtypes;

    resourceUID = lib.mkOption {
        description = "Unique resource identifier of the form <servicename>:path";
        type = types.str;
    };

    dirInfos = types.submodule {
       options = {
            volume = lib.mkOption {
                description = "Volume informations (anything related to the usage: permissions, ...)";
                type = types.volume;
            };
            disk = lib.mkOption {
                description = "Disk information (anything related to the mounting procedure)";
                type = types.disk;
            };
            serviceUID = lib.mkOption {
                description = "UniqueID of the service owning this directory";
                type = types.str;
            };
            env = lib.mkOption {
                description = "Deployement details";
                type = types.deployementEnvironment;
            };
       };   
    };

    vmDisks = types.submodule {
        options = {
            inherit (types) owner reload;
            host = lib.mkOption {
                description = "Path to the host device/ name of the qcow file";
                type = types.str;
            };
            type = lib.mkOption {
                description = "Type of the device";
                type = types.enum ["qcow" "disk"];
            };
            resources = lib.mkOption {
                description = "Unique identifier of the resources present on the disk";
                type = types.listOf resourceUID;
                default = [];
            };

        };
    };
    

in

{
    options.infra.volumes.perDirectory = lib.mkOption {
       description  = "Summary of storage allocations across the infrastructure, each directory being referred using an unique deterministic identifier.";
       type = types.attrsOf dirInfos;
       default = {};
    };
    options.infra.volumes.perVM = lib.mkOption {
       description  = "Summary of storage allocations across the infrastructure, each directory being referred using an unique deterministic identifier.";
       type = types.attrsOf vmDisks;
       default = {};
    };
}
