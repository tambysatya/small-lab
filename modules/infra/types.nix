{lib}:
  let inherit (lib) types;
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
  disk = lib.types.submodule {
    options = {
      src = lib.mkOption { 
        type = lib.types.str;
        description = "device of the host";
        example = "/dev/sda";
      };
      dst = lib.mkOption {
        type = types.str;
        description = "mountpoint on the vm";
        example = "vda";
      };
      bind = lib.mkOption {
        type = types.str;
        description = "Mounting directory";
        example = "/medias/usb";
      };
      options = lib.mkOption {
        type = types.listOf types.str;
        description = "Mounting options";
        default = ["default"];
      };
      fsType = lib.mkOption {
        type = types.str;
        description = "Filesystem";
      };
    };
  };

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
        };
        memory = lib.mkOption {
          type = types.ints.unsigned;
          description = "The size of the memory (MiB) allocated to the VM";
        };
        additionalDisks = lib.mkOption {
          type = types.listOf disk;
          description = "Additional disks that will be passed to the VM";
          example = [{src = "/dev/sdb"; dst="vdb";}];
          default = [];
        };
        ipAddress = lib.mkOption { 
          type = types.str;
          description = "The IP address of the VM";
        };
        services = lib.mkOption {
          type = types.listOf serviceType;
          description = "List of services names deployed on the VM";
          example = ["ldap"];
        };
        containers = lib.mkOption {
          type = types.listOf serviceType;
          description = "List of services names deployed inside a container VM";
          example = ["ldap"];
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
