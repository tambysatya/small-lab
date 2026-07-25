{lib, ...}:

let
  utils = import ../utils.nix {inherit lib;};
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
          name = "default";
          type = "dir";
          target.path = "/var/lib/libvirt/qcow";
          provider = "libvirt.${hostName}";
        };
      };
    resource.libvirt_volume."iso_${hostName}" = {
      name = "nixos-autoinstall.iso";
      pool = "\${resource.libvirt_pool.iso_${hostName}.name}";
      create.content.url = "../result/iso/nixos-minimal-26.05.20260704.a50de1b-x86_64-linux.iso";
      provider = "libvirt.${hostName}";
    };


  };
in {generateHosts = generateHosts;}



