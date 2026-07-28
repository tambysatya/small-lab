{lib, infra, config, vmname, inputs,...}:

/* Bare metal service managment */

let 
    cfg = config.infra-services;
    seclib = import ../security.nix {inherit lib inputs;};

    processServiceEndpoints = infra: vmname: servicename: serviceconf:
        let
            processEndpoint = {host, is_http, port}: #creates an nginx reverse proxy if needed
                {}; #lib.mkMerge (seclib.generateReverseProxy infra vmname host "http://127.0.0.1:${port}");
        in lib.mkMerge [
                (lib.map processEndpoint (
                         lib.filter (endpoint: endpoint.is_http)
                                     serviceconf.endpoints))
            ];


in{
   config = let 
                vmservices = infra.vms."${vmname}".services;
                #configuredservices = {} #lib.filterAttrs (srv: _: builtins.elem srv vmservices) cfg.configs;
                #configuredservices = lib.filterAttrs (srv: _: builtins.elem srv vmservices) {};
                #configuredservices = lib.filter (srv: builtins.hasAttr srv infra.services) vmservices;
                #configuredservices = lib.filterAttrs (_: _: true) cfg.configs;
                _ = builtins.seq cfg.enable null;
            in (lib.mkIf cfg.enable 
                {});
#                (lib.mkMerge [
#                    (lib.mkMerge
#                        (lib.mapAttrsToList (processServiceEndpoints infra vmname)
#                                             configuredservices))
#                ]);
}
