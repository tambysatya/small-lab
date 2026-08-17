{lib}:
let 
    libtypes = lib.types;
    voltypes = import ./volumes.nix {inherit lib;}; 
    types = libtypes //voltypes;
in
types // rec {
	serviceType = 
		lib.types.enum [
			"step-ca"
			"openldap"
			"keycloak"
			"garage"
			"postgres"
			"nextcloud"
		];
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
          type = types.listOf serviceType;
          description = "List of services names deployed on the VM";
          example = ["ldap"];
          default = [];
        };
        containers = lib.mkOption {
          type = types.listOf serviceType;
          description = "List of services names deployed inside a container VM";
          example = ["ldap"];
          default = [];
        };

      };
    };

    /* Virtual machine instance */
    vmInstance = lib.types.submodule {
      options = {
          config = lib.mkOption {
            type = vmConf;
            description = "Description of the VM";
          };
          token = lib.mkOption {
            type = types.str;
            description = "Single-use token to get the AGE privkey from the secret vault";
          };
      };
    };

}
