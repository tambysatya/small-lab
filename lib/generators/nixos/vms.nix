{inputs, lib,...}:

let
  path = "${inputs.self.outPath}";
  utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};

  generateConf = 
    {infra, vmname, vmconf, inputs, config, ...}:
      {
          imports = let path = inputs.self.outPath;
                    in [
                        inputs.sops-nix.nixosModules.sops
                        "${path}/modules/infra"
                        "${path}/modules/infra-services"
                        "${path}/modules/disko-vm.nix"
                        "${path}/profiles/vm.nix"
                        "${path}/modules/step-renew"
                        "${path}/modules/step-ca.nix"
                        "${path}/modules/openldap.nix"
                        "${path}/modules/keycloak.nix"
                        "${path}/modules/garage.nix"
                        "${path}/modules/postgres.nix"
                    ];


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
              fileSystems = utils.mergeAll (lib.map 
                              (disk: {
                                      "${disk.bind}" = {
                                          device = "/dev/${disk.dst}";   
                                          fsType = disk.fsType;
                                          options = disk.options;
                                      };
                                }) vmconf.additionalDisks);
              services.openssh.enable = true;
              users.users.root.openssh.authorizedKeys.keys = infra.root_ssh_pubkeys;

              /* Initializes step-renew */
              services.step-renew  = {
                  enable = true;
                  caURL = infra.ca.url;
                  caFingerprint = builtins.readFile "${path}/secrets/plain/CA/fingerprint"; # the fingerprint is also generated with the bootstrap script
              };


              networking.firewall = { #TODO
                allowedTCPPorts = [22]; # ++ generateTCPPorts vmconf.services 
                allowedUDPPorts = []; # ++ generateUDPPorts vmconf.services
              };
        };  
in {

  # Generates the configuration of a given VM
  # Infra -> VMName -> VMConf -> NixOSModule

  generateConf = generateConf;

}
