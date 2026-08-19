{lib}:
let inherit (lib) types;
in

rec {
  mapping= lib.types.submodule { # Additional directory to be mounted
    options = {
        vol = lib.mkOption {
            description = "Location of the directory in the volume";
            type = types.str;
        };
        sys = lib.mkOption {
            description = "Mountpoint in the system";
            type = types.str;
        };
    };
  };
  fsMount = lib.types.submodule { # VM-side mounting options of a volume
    options = {
      dir = lib.mkOption { 
        type = types.str;
        description = "mountpoint on the vm";
        example = "/medias/storage";
      };
      options = lib.mkOption {
        type = types.listOf types.str;
        description = "Mounting options";
        default = ["default"];
      };
      fsType = lib.mkOption {
        type = types.enum ["xfs" "ext4"]; #TODO
        description = "Filesystem";
      };
    };
  };
  disk = lib.types.submodule { # A raw disk to be mounted in the VM
    options = {
      src = lib.mkOption { 
        type = lib.types.str;
        description = "device of the host";
        example = "/dev/sda";
      };
      mount = lib.mkOption {
        description = "Mounting point configuration";
        type = fsMount;
      };
      mapping = lib.mkOption {
        description = "List of directories to be bind-mounted";
        type = types.listOf mapping;
        default = [];
      };
    };
  };
  qcow = lib.types.submodule {
    options = {
        name = lib.mkOption {
            description = "Name of the QCOW volume";
            type = types.str;
            example = "persistent";
        };
        size = lib.mkOption {
            description = "Size of the volume (in bytes)";
            type = types.ints.positive;
            example = 1024*1024*1024; #1G
            default = 100*1024*1024; #100 Mo
        };
        mount = lib.mkOption {
            description = "Mounting point configuration";
            type = fsMount;
        };
        mapping = lib.mkOption {
            description = "List of directories to be bind-mounted";
            type = types.listOf mapping;
            default = [];
        };
     };
    };
    volumesList = lib.types.submodule {
        options = {
            disks = lib.mkOption {
                description = "Mapping between mountpoints (on the vm) and raw disks (on the host). The devices need to exist on the host. Useful for large files (e.g. databases)";
                type = types.listOf disk;
                default = [];
                example = [
                    {
                        src = "/dev/sdb"; 
                        target = {
                            device = "vdb";
                            options = ["nofail"];
                            fstType = "xfs";
                        };
                    }
                ];
            };
            qcows = lib.mkOption {
                description = "Mapping between mountpoints (on the vm) and qcow volumes (on the host). Useful for small files (e.g. config states). The volumes will be created or resized by libvirt dynamically. Please note that in case of resizing, the VM will NOT see the change until you apply manually the resizing procedure of the corresponding filesystem type, e.g. resize2fs or xfs_growfs";
                type = types.listOf qcow;
                default = [];
                example = {
                    "/srv/volume" = {
                        name = "vm1-persistent"; 
                        size = 1024*1024*100; #100 M
                        target = {
                            device = "vdb";
                            options = ["nofail"];
                            fstType = "xfs";
                            mounts = [{src = "config.php"; dst = "/var/lib/nextcloud/config/config.php"; type="file";}];
                        };
                    };
                };
            };
        };
  };

}

