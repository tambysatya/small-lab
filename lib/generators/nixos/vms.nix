{inputs, lib,...}:

let
  path = "${inputs.self.outPath}";
  utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};

  services = import ./services {inherit inputs lib;};
  serviceGenerator = services.generator;

  # generates the services configuration for each service deployed on the VM
  allServicesModules = infra: vmName: vmConf: lib.map (serviceName: serviceGenerator infra vmName vmConf serviceName) vmConf.services;

  generateConf = infra: vmName: vmConf: 
    {inputs, config, ...}:
        utils.mergeAll ([{

          imports = let path = inputs.self.outPath;
                    in ["${path}/modules/disko-vm.nix"
                        "${path}/profiles/vm.nix"
                        "${path}/modules/step-renew"
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

          /* Initializing step-renew */
          services.step-renew  = {
              enable = true;
              caURL = infra.ca.url;
              caFingerprint = builtins.readFile "${path}/secrets/plain/CA/fingerprint";
          };

          /* Initializing sops */
          sops.age.keyFile = "/var/lib/sops-nix/key.txt";

          networking.firewall = { #TODO
            allowedTCPPorts = [22]; # ++ generateTCPPorts vmConf.services 
            allowedUDPPorts = []; # ++ generateUDPPorts vmConf.services
          };
      }] 
      ++ (allServicesModules infra vmName vmConf)
      );
in {

  # Generates the configuration of a given VM
  # Infra -> VMName -> VMConf -> NixOSConfig

  generateConf = generateConf;
  generateVMs = infra: utils.mergeAll (lib.mapAttrsToList (generateConf infra) (infra.vms));

}
