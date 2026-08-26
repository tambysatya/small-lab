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
              type = types.listOf types.str;  
              description = "List of services identifier deployed on the VM";
              example = ["openldap-main"]; #TODO check if they are declared
              default = [];
            };
            containers = lib.mkOption {
              type = types.listOf types.str;
              description = "List of services identifier deployed inside a container VM";
              example = ["ldap"];
              default = [];
            };

            test = lib.mkOption {
                type = types.bool;
                description = "The machine is used for tests and will belong to a specific zone";
                default = false;
            };
          };
        };


}
