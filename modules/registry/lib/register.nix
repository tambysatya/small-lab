{inputs, lib, infra, vmname,  ...}:

/* Called by the modules to register services properties*/

let 
    registerSecret = servicename: secretname: secret: {
        infra-services.enable = true;
        infra-services.registry.services."${servicename}".secrets."${secretname}" = {
                                        path = secret.path or "/run/secrets/${secretname}";
                                        mode = secret.mode or "0400";
                                        owner = secret.owner or "root";
                                        reload = secret.reload or [];
                                    }; 
    };
    registerSecrets = servicename: owner: reload: secrets:
        lib.mkMerge 
            (lib.mapAttrsToList 
                (secretname: secret: 
                    let sec = {
                            path = secret.path or "/run/secrets/${secretname}";
                            mode = secret.mode or "0400";
                            owner = owner;
                            reload = reload;
                        };
                    in registerSecret servicename secretname sec)
                secrets);

    registerCertificate = servicename: owner: reload: vhost:
        lib.mkMerge [
                (registerSecrets servicename owner reload {
                        "${vhost}.crt" = {path = "/run/secrets/${vhost}.crt";};
                        "${vhost}.key" = {path = "/run/secrets/${vhost}.key";};
                    })
                {
                    infra-services.enable = true;
                    infra-services.registry.services."${servicename}".sslCertificates."${vhost}" = {
                        cert = "/run/secrets/${vhost}.crt";
                        key = "/run/secrets/${vhost}.key";
                        reload = reload;
                    };
                    
                }
        ];

    registerEndpoints = servicename: endpoints:
        lib.mkMerge [
            {
                infra-services.enable = true;
                infra-services.registry.services."${servicename}".endpoints = endpoints;
            }
            #registers SSL certificates for each endpoints asking for HTTPS reverse proxy
            (lib.mkMerge 
                (lib.map
                    (ep: registerCertificate servicename "nginx" ["nginx.service"] ep.host)
                    (lib.filter (ep: ep.is_http or true) endpoints)))
            
        ];

    registerDBAccess = servicename: secretowner: access:
        let secret = {
               path = "/run/secrets/${servicename}-${access.table}-db.key";
               owner = secretowner;
               reload = access.serviceUnits;

            };
        in lib.mkMerge [
            (registerSecret servicename "${servicename}-${access.table}-db.key" secret)
            {
                infra-services.registry.vms."${vmname}".use-db = [servicename];
                infra-services.registry.services."${servicename}".dbAccesses = [access];
            }
        ];
    registerS3Access = servicename: secretowner: access:
        let secrets =  {
            "${servicename}-${access.bucket}-s3-id.key" = {
                   path = "/run/secrets/${servicename}-${access.bucket}-s3-id.key";
                   owner = secretowner;
                   reload = access.serviceUnits;

                };
            "${servicename}-${access.bucket}-s3.key" = {
                   path = "/run/secrets/${servicename}-${access.bucket}-s3.key";
                   owner = access.role;
                   reload = access.serviceUnits;

                };

            };
        in lib.mkMerge [
            (registerSecrets servicename secretowner access.serviceUnits secrets)
            {
                infra-services.registry.vms."${vmname}".use-s3 = [servicename];
                infra-services.registry.services."${servicename}".S3Accesses = [access];
            }
        ];
 
        

in {
    inherit registerSecrets registerCertificate registerEndpoints registerDBAccess registerS3Access;
}
