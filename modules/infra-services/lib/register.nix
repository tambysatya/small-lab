{inputs, lib, infra, vmname,  ...}:

/* Called by the modules to register services properties*/

let 
    registerSecret = servicename: owner: reload: secretname: secret: {
        infra-services.enable = true;
        infra-services.registry."${servicename}".secrets."${secretname}" = 
            {
                inherit (secret) path;
                mode = secret.mode or "0400";
                owner = owner;
                restartUnits = reload;
            };
    };
    registerSecrets = servicename: owner: reload: secrets:
        lib.mkMerge (lib.mapAttrsToList (registerSecret servicename owner reload) secrets);

    registerCertificate = servicename: owner: reload: vhost:
        lib.mkMerge [
                (registerSecrets servicename owner reload {
                        "${vhost}.crt" = {path = "/var/lib/${owner}/${vhost}.crt";};
                        "${vhost}.key" = {path = "/var/lib/${owner}/${vhost}.key";};
                    })
                {
                    services.step-renew  = {
                        enable = true;
                        caURL = infra.caURL;
                        caFingerprint = builtins.readFile "${inputs.self.outPath}/secrets/plain/CA/fingerprint";
                        certs."${vhost}" = {
                            cert = "/var/lib/${owner}/${vhost}.crt";
                            key = "/var/lib/${owner}/${vhost}.key";
                            reload = reload;
                        };
                    };
                }
        ];

    registerEndpoints = servicename: endpoints:{
        infra-services.enable = true;
        infra-services.registry."${servicename}".endpoints = endpoints;
    };
        

in {
    inherit registerSecrets registerCertificate registerEndpoints;
}
