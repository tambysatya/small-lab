{lib, inputs, config, ...}:

let
 

in 
{

imports = let path = inputs.self.outPath;
            in [
                ./base.nix

             ];


config = {
     
              boot.kernelParams = ["console=tty1" "console=ttyS0,115200"];
              boot.loader.systemd-boot.enable = true;
              boot.loader.efi.canTouchEfiVariables = true;
              time.timeZone = "Europe/Paris";
              i18n.defaultLocale = "fr_FR.UTF-8";



              services.openssh.enable = true;


              networking.firewall = { #TODO
                allowedTCPPorts = [22]; # ++ generateTCPPorts vmconf.services 
                allowedUDPPorts = []; # ++ generateUDPPorts vmconf.services
              };
        };  
}
