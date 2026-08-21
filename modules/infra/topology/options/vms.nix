{lib, inputs, ...}:
let 
    libtypes = lib.types;
    voltypes = import ./volumes.nix {inherit lib inputs;}; 
    mytypes = import "${inputs.self.outPath}/lib/types" {inherit lib inputs;};
    types = libtypes //voltypes // mytypes;
in
{

    /* Virtual machine description */
    vmConf = lib.types.submodule {
        options = {
            host = lib.mkOption {
              type = types.str;
              description = "The host where the the VM will be created";
            };
            vcpu = lib.mkOption {
              type = types.ints.unsigned;
              description = "The number of vCPUS allocated to the VM";
              default = 1;
            };
            memory = lib.mkOption {
              type = types.ints.unsigned;
              description = "The size of the memory (MiB) allocated to the VM";
              default = 1024;
            };
            persistentVolumes = lib.mkOption {
              type = types.volumesList;
              description = "Additional volumes that will be passed to the VM";
            };
            ipAddress = lib.mkOption { 
              type = types.str;
              description = "The IP address of the VM";
            };
            services = lib.mkOption {
              type = types.listOf types.serviceType;
              description = "List of services names deployed on the VM";
              example = ["ldap"];
              default = [];
            };
            containers = lib.mkOption {
              type = types.listOf types.serviceType;
              description = "List of services names deployed inside a container VM";
              example = ["ldap"];
              default = [];
            };

          };
        };


}
