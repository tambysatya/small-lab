{lib, ...}:

let
  utils = import ../../utils.nix {inherit lib;};
  generateHosts = infra: lib.foldl' utils.merge {} (lib.mapAttrsToList generateHost infra.hosts); # generates the list of pools/resources for each host
  generateHost = hostName: host: { # generates a single host
      provider.libvirt = [{
        uri = "qemu+ssh://root@${host.ipAddress}/system"; 
        alias = hostName;
      }];
      resource.libvirt_pool = {
        "iso_${hostName}" = {
          name = "iso";
          type = "dir";
          target.path = "/var/lib/libvirt/iso";
          provider = "libvirt.${hostName}";
        };
        "default_${hostName}" = {
          name = "qcow";
          type = "dir";
          target.path = "/var/lib/libvirt/qcow/terranix";
          provider = "libvirt.${hostName}";
        };
      };
    resource.libvirt_volume."iso_${hostName}" = {
      name = "nixos-autoinstall.iso";
      pool = "\${resource.libvirt_pool.iso_${hostName}.name}";
      create.content.url = "bootstrap.iso";
      provider = "libvirt.${hostName}";
    };


  };
in {generateHosts = generateHosts;}



