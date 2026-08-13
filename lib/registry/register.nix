{inputs, lib, infra, vmname, vmconf,  ...}:

/* Called by the modules to register services properties*/

let 
    infralib = import "${inputs.self.outPath}/lib/infra" {inherit inputs lib vmname vmconf;};
    registerSecret = servicename: secretname: secret: {
        registry.services."${servicename}".secrets."${secretname}" = {
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
                    registry.services."${servicename}".sslCertificates."${vhost}" = {
                        cert = "/run/secrets/${vhost}.crt";
                        key = "/run/secrets/${vhost}.key";
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
            (lib.mkIf (infralib.hostsService servicename) {registry.vms."${vmname}".use-db = [servicename];})
            {
                registry.services."${servicename}".dbAccesses = [access];
            }
        ];
    registerS3Access = servicename: access:
        lib.mkMerge [
            (lib.mkIf (infralib.hostsService servicename) {registry.vms."${vmname}".use-s3 = [servicename];})
            {
                registry.services."${servicename}".s3Accesses = [access];
            }
        ];
 
        

in {
    inherit registerSecrets registerCertificate registerEndpoints registerDBAccess registerS3Access;
}
