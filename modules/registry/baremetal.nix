{lib, infra, registry, config, vmname, inputs,...}:

/* Bare metal service managment */

let 
    sec = import ./lib/security.nix {inherit lib inputs registry infra vmname;};

    processEndpoints = servicename: reg:
        let
            processEndpoint = {host, is_http, port}: #creates an nginx reverse proxy if needed
                if is_http
                then (sec.generateReverseProxy host "http://127.0.0.1:${lib.toString port}")
                else {}; #TODO pnat
        in lib.mkMerge 
                (lib.map processEndpoint (
                         lib.filter (endpoint: endpoint.is_http)
                                     (reg.endpoints or {})));

    processSecrets = servicename: reg:
        lib.mkMerge 
            (lib.mapAttrsToList
                   (sec.generateSecret servicename)
                   (reg.secrets or {}));
    processCertificates = servicename: reg:
        lib.mkMerge
            (lib.mapAttrsToList
                (sec.generateCertificate servicename)
                (reg.sslCertificates or {}));
        


in{
   config = let 
                vmservices = infra.vms."${vmname}".services;
                configuredservices = lib.filterAttrs (srv: _: builtins.elem srv vmservices) registry.services;
                #configuredservices = lib.filter (srv: builtins.hasAttr srv registry) vmservices;
                _ = builtins.seq registry null;
            #in lib.mkIf cfg.enable (builtins.seq configuredservices {});
            in (lib.mkMerge [
                        (lib.mkMerge
                            (lib.mapAttrsToList processEndpoints configuredservices))
                        (lib.mkMerge
                            (lib.mapAttrsToList processSecrets configuredservices))
                        (lib.mkMerge
                            (lib.mapAttrsToList processCertificates configuredservices))

                    ]);
}
