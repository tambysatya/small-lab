{lib, infra, registry, vmname, vmconf, inputs, config, ...}:

let
  path = "${inputs.self.outPath}";
  utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};

in 
{

imports = let path = inputs.self.outPath;
            in [
                inputs.sops-nix.nixosModules.sops
                "${path}/profiles/base.nix"

             ];


config = {
     
              boot.kernelParams = ["console=tty1" "console=ttyS0,115200"];

              boot.loader.systemd-boot.enable = true;
              boot.loader.efi.canTouchEfiVariables = true;
              time.timeZone = "Europe/Paris";
              i18n.defaultLocale = "fr_FR.UTF-8";



              networking = {
                hostName = vmname;
                interfaces.enp1s0 = {
                  useDHCP = false;
                  ipv4 = {
                    addresses = [
                      {address = vmconf.ipAddress; prefixLength = 24;}
                    ];
                    routes = [
                      {address = "0.0.0.0"; via = infra.gateway; prefixLength = 0;}
                    ];
                  };
                };
                nameservers = infra.dns;
              };

              /* Mounts additional disks */
              fileSystems = utils.mergeAll (lib.mapAttrsToList
                              (bind: disk: {
                                      bind = {
                                          device = "/dev/${disk.dst}";   
                                          fsType = disk.fsType;
                                          options = disk.options;
                                      };
                                }) vmconf.additionalDisks);
              services.openssh.enable = true;
              users.users.root.openssh.authorizedKeys.keys = infra.root_ssh_pubkeys;


              networking.firewall = { #TODO
                allowedTCPPorts = [22]; # ++ generateTCPPorts vmconf.services 
                allowedUDPPorts = []; # ++ generateUDPPorts vmconf.services
              };
        };  
}
