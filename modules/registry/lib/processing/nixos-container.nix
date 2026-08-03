{lib, infra, registry, config, vmname, vmconf, inputs,pkgs,...}:

/* Deployement of services behind a container */



let

    sec = import ../security.nix {inherit lib inputs registry infra vmname;};
    initialize-host = {
          networking.nat = {
            enable = true;
            internalInterfaces = ["ve-+"];
            externalInterface = "enp1s0";
            enableIPv6 = true;
      };
    };

    # creates an entry of containers= on the host
    mkContainer = {servicename, host-addr, local-addr}:  
        {
           containers."ct-${servicename}" = 
               let ct-name = "ct-${servicename}";
                   ct-conf = {
                        inherit (vmconf) host vcpu memory;
                        services = [servicename];
                   };
               in {
                    specialArgs = {inherit inputs infra registry; vmname=ct-name; vmconf=ct-conf;}; #TODO
                    #specialArgs = {inherit infra registry; vmname=ct-name; vmconf=ct-conf;}; #TODO
                    autoStart = true;
                    privateNetwork = true;
                    hostAddress = host-addr;
                    localAddress = local-addr;
                    bindMounts."/var/lib/sops-nix/key.txt" = { #mounting the age key of the volume
                        hostPath = "/run/secrets/ct-${servicename}.key";
                        isReadOnly = true;
                    };
                    config = {...}:{
                        infra-compiler = {
                            no-endpoints = true; #do not process endpoints
                        };
                        imports = [
                            "${inputs.self.outPath}/modules/${servicename}"

                            "${inputs.self.outPath}/modules/step-renew"
                            "${inputs.self.outPath}/profiles/base.nix"
                            "${inputs.self.outPath}/modules/registry"
                            "${inputs.self.outPath}/modules/registry/lib/processing/baremetal.nix"
                            inputs.sops-nix.nixosModules.sops
                            
                        ]; 
                        networking.hostName = "ct-${servicename}";
                        time.timeZone = "Europe/Paris";
                        i18n.defaultLocale = "fr_FR.UTF-8";
                    };

           };
        };

in{ 

config = lib.mkIf (vmconf.containers != []) 
            (lib.mkMerge [
                (initialize-host)
                (lib.mkMerge 
                        (lib.imap
                            (i: servicename: 
                                let local-addr = "192.168.100.${lib.toString (50+i)}";
                                in lib.mkMerge [
                                    (mkContainer {inherit servicename local-addr; host-addr= "192.168.100.10";})
                                    (sec.generateSecret "ct-${servicename}" "ct-${servicename}.key" {reload = ["container@ct-${servicename}.service"];})
                                    (lib.mkIf (lib.hasAttr servicename registry.services)
                                        (lib.mkMerge 
                                            (lib.map 
                                                (ep: if ep.is_http then
                                                        sec.generateReverseProxy {
                                                            fronthost = ep.host;
                                                            backhost = "http://${local-addr}";
                                                            inherit (ep) extraNginxConfig;}
                                                     else
                                                        {})
                                                registry.services.${servicename}.endpoints)))
                                ])
                            vmconf.containers))
            ]);

}
