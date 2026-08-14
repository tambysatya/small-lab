{lib, infra, registry, config, vmname, vmconf, inputs,...}:

/* Bare metal service managment */

let 
    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit lib infra registry inputs;};
    sec = import "${inputs.self.outPath}/lib/registry/security.nix" {inherit lib inputs registry infra vmname;};

    processEndpoints = servicename: reg:
        let
            processEndpoint = {host, is_http, port, extraNginxConfig ? "",...}: #creates an nginx reverse proxy if needed
                if is_http
                then sec.generateReverseProxy {fronthost = host; 
                                               backhost = "http://127.0.0.1:${lib.toString port}";
                                               inherit extraNginxConfig;}
                else {}; #TODO pnat
        in lib.mkIf (! config.registry-compiler.no-endpoints)
            (lib.mkMerge 
                (lib.map processEndpoint (
                         lib.filter (endpoint: endpoint.is_http)
                                     (reg.endpoints or {}))));

    processSecrets = servicename: reg:
        lib.mkMerge 
            (lib.mapAttrsToList
                   (_: secret: sec.generateSecret secret)
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
                    let secretname = vars.db_key access;
                    in sec.generateSecret 
                        { names=[secretname]; inherit (access) owner reload;} )
                (reg.dbAccesses or []));

    # Generates the secrets for a service requesting S3 accesses
    processS3AccessClient = servicename: reg:
        lib.mkMerge
            (lib.map 
                (access:
                    (sec.generateSecret 
                        {names = [vars.s3_key access]; inherit (access) owner reload;}))
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
