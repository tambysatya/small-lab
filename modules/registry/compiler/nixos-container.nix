{lib, infra, registry, config, vmname, vmconf, inputs,pkgs,...}:

/* Deployement of services behind a container */



let

    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit lib infra registry inputs pkgs;};
    sec = import "${inputs.self.outPath}/lib/registry/security.nix" {inherit lib inputs registry infra vmname;};
    deps = import "${inputs.self.outPath}/lib/registry/infra-dependencies.nix" {inherit lib inputs registry infra vmname pkgs;};

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
           containers."${servicename}" = 
               let ct-name = vars.container_id vmname servicename;
                   ct-conf = {
                        inherit (vmconf) host vcpu memory;
                        services = [servicename];
                        containers = [];
                   };
               in {
                    specialArgs = {inherit inputs infra registry; vmname=ct-name; vmconf=ct-conf;}; #TODO
                    autoStart = true;
                    privateNetwork = true;
                    hostAddress = host-addr;
                    localAddress = local-addr;
                    bindMounts."/var/lib/sops-nix/key.txt" = { #mounting the age key of the volume
                        hostPath = "/run/secrets/${ct-name}.key";
                        isReadOnly = true;
                    };
                    config = {...}:{
                        registry-compiler = {
                            no-endpoints = true; #do not process endpoints
                        };
                        imports = [
                            
                            "${inputs.self.outPath}/services/${servicename}"

                            "${inputs.self.outPath}/services/step-renew"
                            "${inputs.self.outPath}/profiles/base.nix"
                            "${inputs.self.outPath}/modules/registry"
                            "${inputs.self.outPath}/modules/registry/compiler/native.nix"
                            inputs.sops-nix.nixosModules.sops
                            
                        ]; 
                        networking.hostName = ct-name;
                        time.timeZone = "Europe/Paris";
                        i18n.defaultLocale = "fr_FR.UTF-8";
                    };

           };
           systemd.services."containers@${servicename}" = {
                serviceConfig.TimeoutStartUSec = "5min"; #To avoid premature halting if the infra-deps are not satisfied immediately
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
                                    container_id = vars.container_id vmname servicename;
                                in lib.mkMerge [
                                    (mkContainer {inherit servicename local-addr; host-addr= "192.168.100.10";})
                                    (sec.generateSecret 
                                            {names = ["${container_id}.key"]; reload = ["container@ct-${servicename}.service"];})
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

                # Containers requesting a DBAccess cannot be launched before postgres is reachable
                (deps.mkDBDependencies 
                    (lib.map 
                        (servicename: "container@${servicename}.service")
                        (lib.filter 
                            (servicename: builtins.hasAttr servicename registry.services &&
                                          (registry.services."${servicename}".dbAccesses != [])) 
                            vmconf.containers)))
            ]);

}
