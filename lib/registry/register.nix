{inputs, lib, infra,  ...}:

/* Called by the modules to register services properties*/

let 
    registerSecret = servicename: secretname: secret: let
        provider = secret.kind.provider;
        providerargs = secret.kind.providerArgs or {};
        opensslArgs  = {
            size = providerargs.size or 64;
            type = providerargs.type or "base64";
        };

        addDefault = secret: { #sets the default values depending on which provider is selected
            inherit (secret) names;
            mode = secret.mode or "0400";
            owner = secret.owner or "root";
            reload = secret.reload or [];
            kind = {
                inherit provider;
                providerArgs = if provider == "openssl" then opensslArgs else providerargs;
            };
        };
    in{
        registry.services."${servicename}".secrets."${secretname}" = addDefault secret;
    };

    registerCertificate = servicename: owner: reload: vhost:
        lib.mkMerge [
                {
                    registry.services."${servicename}".sslCertificates."${vhost}" = {
                        inherit owner reload;
                    };
                    
                }
        ];

    registerEndpoints = servicename: endpoints:
        lib.mkMerge [
            {
                registry.services."${servicename}".endpoints = endpoints;
            }
        ];

    registerDBAccess = servicename: access:
        lib.mkMerge [
            {
                registry.services."${servicename}".dbAccesses = [access];
            }
        ];
    registerS3Access = servicename: access:
        lib.mkMerge [
            {
                registry.services."${servicename}".s3Accesses = [access];
            }
        ];

    registerVolume = servicename: volume:
        lib.mkMerge [
            {
                registry.services."${servicename}".volumes = [volume];
            }
        ];

    registerUser = servicename: username: userid:
        lib.mkMerge [
            { registry.services."${servicename}".users.${username} = userid;}
        ];
 
        

in {
    inherit registerSecret registerCertificate registerEndpoints registerDBAccess registerS3Access registerVolume registerUser;
}
