{inputs, lib, infra, vmname,  ...}:

/* Called by the modules to register services properties*/

let 
    registerSecret = servicename: secretname: secret: {
        infra-services.enable = true;
        infra-services.registry.services."${servicename}".secrets."${secretname}" = secret; 
    };
    registerSecrets = servicename: owner: reload: secrets:
        lib.mkMerge 
            (lib.mapAttrsToList 
                (secretname: secret: 
                    let sec = {
                            inherit (secret) path;
                            mode = secret.mode or "0400";
                            owner = owner;
                            reload = reload;
                        };
                    in registerSecret servicename secretname sec)
                secrets);

    registerCertificate = servicename: owner: reload: vhost:
        lib.mkMerge [
                (registerSecrets servicename owner reload {
                        "${vhost}.crt" = {path = "/var/lib/${owner}/${vhost}.crt";};
                        "${vhost}.key" = {path = "/var/lib/${owner}/${vhost}.key";};
                    })
                {
                    infra-services.enable = true;
                    infra-services.registry.services."${servicename}".sslCertificates."${vhost}" = {
                        cert = "/var/lib/${owner}/${vhost}.crt";
                        key = "/var/lib/${owner}/${vhost}.key";
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
               path = "/run/secrets/${servicename}-${access.table}db.key";
               owner = access.role;
               reload = access.serviceUnits;

            };
        in lib.mkMerge [
            (registerSecret secretowner "${servicename}-db.key" secret)
            {
                infra-services.registry.vms."${vmname}".use-db = [servicename];
                infra-services.registry.services."${servicename}".dbAccesses = [access];
            }
        ];
    registerS3Access = servicename: secretowner: access:
        let secrets =  {
            "${servicename}-s3-id.key" = {
                   path = "/run/secrets/${servicename}-s3-id.key";
                   owner = access.role;
                   reload = access.serviceUnits;

                };
            "${servicename}-s3.key" = {
                   path = "/run/secrets/${servicename}-s3.key";
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
