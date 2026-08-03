{lib, infra, registry, config, vmname, vmconf, inputs,...}:

/* Bare metal service managment */

let 
    sec = import ../security.nix {inherit lib inputs registry infra vmname;};

    processEndpoints = servicename: reg:
        let
            processEndpoint = {host, is_http, port}: #creates an nginx reverse proxy if needed
                if is_http
                then (sec.generateReverseProxy host "http://127.0.0.1:${lib.toString port}")
                else {}; #TODO pnat
        in lib.mkIf (! config.infra-compiler.no-endpoints)
            (lib.mkMerge 
                (lib.map processEndpoint (
                         lib.filter (endpoint: endpoint.is_http)
                                     (reg.endpoints or {}))));

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

    # Generates the secrets for a service requesting database accesses
    processDBAccessClient = servicename: reg:
        lib.mkMerge 
            (lib.map
                (access:
                    let secretname = "${servicename}-${access.table}-db.key";
                    in sec.generateSecret servicename secretname 
                        {inherit (access) owner reload;} )
                (reg.dbAccesses or []));

    # Generates the secrets for a service requesting S3 accesses
    processS3AccessClient = servicename: reg:
        lib.mkMerge
            (lib.map 
                (access:
                    let secret-basename = "${servicename}-${access.bucket}-s3";
                    in lib.mkMerge [
                            (sec.generateSecret servicename "${secret-basename}-id.key"
                                {inherit (access) owner reload;})
                            (sec.generateSecret servicename "${secret-basename}.key"
                                {inherit (access) owner reload;})
                        ])
                (reg.S3Accesses or []));


in{
   config = let 
                configuredservices = if builtins.hasAttr "services" vmconf
                                        then lib.filterAttrs (srv: _: builtins.elem srv vmconf.services) registry.services
                                        else {};
                hostedservices = if builtins.hasAttr "containers" vmconf
                                    then lib.filterAttrs (srv: _: builtins.elem srv vmconf.containers) registry.services
                                    else {};
                #configuredservices = lib.filter (srv: builtins.hasAttr srv registry) vmservices;
                _ = builtins.seq registry null;
            #in lib.mkIf cfg.enable (builtins.seq configuredservices {});
            in (lib.mkMerge [
                        (lib.mkMerge
                            (lib.mapAttrsToList processEndpoints configuredservices))
                        (lib.mkMerge
                            (lib.mapAttrsToList processSecrets configuredservices))
                        (lib.mkMerge
                            (lib.mapAttrsToList processCertificates (configuredservices // hostedservices)))
                        (lib.mkMerge
                            (lib.mapAttrsToList processDBAccessClient configuredservices))
                        (lib.mkMerge
                            (lib.mapAttrsToList processS3AccessClient configuredservices))

                    ]);
}
