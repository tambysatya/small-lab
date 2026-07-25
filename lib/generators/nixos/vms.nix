{lib,...}:

let
  utils = import ../utils.nix {inherit lib;};
  generateConf = infra: vmName: vmConf: 
    {inputs, config, lib, pkgs,...}:
        {

          imports = let path = inputs.self.outPath;
                    in ["${path}/modules/disko-vm.nix"
                        "${path}/profiles/vm.nix"
                    ];

          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;
          time.timeZone = "Europe/Paris";
          i18n.defaultLocale = "fr_FR.UTF-8";



          networking = {
            hostName = vmName;
            interfaces.enp1s0 = {
              useDHCP = false;
              ipv4 = {
                addresses = [
                  {address = vmConf.ipAddress; prefixLength = 24;}
                ];
                routes = [
                  {address = "0.0.0.0"; via = infra.gateway; prefixLength = 0;}
                ];
              };
            };
            nameservers = infra.dns;
          };

          fileSystems = utils.mergeAll (lib.map 
                          (disk: {
                                  "${disk.bind}" = {
                                      device = "/dev/${disk.dst}";   
                                      fsType = disk.fsType;
                                      options = disk.options;
                                  };
                            }) vmConf.additionalDisks);
          services.openssh.enable = true;
          users.users.root.openssh.authorizedKeys.keys = infra.root_ssh_pubkeys;

          networking.firewall = { #TODO
            allowedTCPPorts = [22]; # ++ generateTCPPorts vmConf.services 
            allowedUDPPorts = []; # ++ generateUDPPorts vmConf.services
          };
  };
in {

  generateConf = generateConf;
  generateVMs = infra: utils.mergeAll (lib.mapAttrsToList (generateConf infra) (infra.vms));

}
