{inputs, lib, infra, vmname, vmconf,  ...}:

/* Called by the modules to register services properties*/

let 
    infralib = import "${inputs.self.outPath}/modules/infra/lib.nix" {inherit lib vmname vmconf;};
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
                {
                    infra-services.enable = true;
                    infra-services.registry.services."${servicename}".sslCertificates."${vhost}" = {
                        cert = "/run/secrets/${vhost}.crt";
                        key = "/run/secrets/${vhost}.key";
                        inherit owner reload;
                    };
                    
                }
        ];

    registerEndpoints = servicename: endpoints:
        lib.mkMerge [
            {
                infra-services.enable = true;
                infra-services.registry.services."${servicename}".endpoints = endpoints;
            }
        ];

    registerDBAccess = servicename: access:
        lib.mkMerge [
            (lib.mkIf (infralib.hostsService servicename) {infra-services.registry.vms."${vmname}".use-db = [servicename];})
            {
                infra-services.registry.services."${servicename}".dbAccesses = [access];
            }
        ];
    registerS3Access = servicename: access:
        lib.mkMerge [
            (lib.mkIf (infralib.hostsService servicename) {infra-services.registry.vms."${vmname}".use-s3 = [servicename];})
            {
                infra-services.registry.services."${servicename}".S3Accesses = [access];
            }
        ];

    registerVolume = servicename : volumename: volume:
        {
            infra-services.registry.services."${servicename}".volumes.${volumename} = volume;
        };
 
        

in {
    inherit registerSecrets registerCertificate registerEndpoints registerDBAccess registerS3Access registerVolume;
}
