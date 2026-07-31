
{lib, inputs, config, ...}:

let
  path = "${inputs.self.outPath}";
  utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};

in 
{

imports = let path = inputs.self.outPath;
            in [
                inputs.sops-nix.nixosModules.sops
                ../modules/disko-vm.nix
                ./base.nix

            ];


config = {
     
              boot.loader.systemd-boot.enable = true;
              boot.loader.efi.canTouchEfiVariables = true;
              time.timeZone = "Europe/Paris";
              i18n.defaultLocale = "fr_FR.UTF-8";



              networking = {
                hostName = "disko";
                interfaces.enp1s0.useDHCP = true;
              };

              services.openssh.enable = true;


              networking.firewall = { #TODO
                allowedTCPPorts = [22]; # ++ generateTCPPorts vmconf.services 
                allowedUDPPorts = []; # ++ generateUDPPorts vmconf.services
              };
        };  
}
