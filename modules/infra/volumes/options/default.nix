{lib, inputs, config,...}:

let
    libtypes = import "${inputs.self.outPath}/lib/types" {inherit lib inputs;};
    types = lib.types // libtypes;

    volumeInfos = types.submodule {
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
    

in

{
    options.infra.volumes = lib.mkOption {
       description  = "Summary of storage allocations across the infrastructure, each directory being referred using an unique deterministic identifier.";
       type = types.attrsOf volumeInfos;
       default = {};
    };
}
