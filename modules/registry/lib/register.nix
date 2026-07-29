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
        

in {
    inherit registerSecrets registerCertificate registerEndpoints;
}
