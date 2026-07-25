{inputs, lib, ...}:


let secretLib = import ./secrets.nix {inherit inputs lib;}; 

in {

  /* Generates the secret and the auto-refresh service for a given certificate.
     registerCertificate : vmName -> owner -> serviceName -> NixosConfig

     - the secret will be stored in /var/lib/owner/serviceName.{crt,key}
     - the reload units are set to [ "serviceName.service" ]
  */
     
  registerCertificate =
    vmName: owner: serviceName:
      let sslCert = "/var/lib/${owner}/${serviceName}.crt";
          sslCertKey = "/var/lib/${owner}/${serviceName}.key";
          unit = "${serviceName}.service"
          secrets = {
                      "${serviceName}.crt" = {
                          path = sslCert;
                      };
                      "${serviceName}.key" = {
                          path = sslCertKey;
                      };
                    };
      in{
        sops.secrets = secretLib.generateSecrets vmName owner [unit] secrets;
        services.step-renew.serviceName = {
          cert = sslCert;
          key = sslKey;
          reload = [unit];
        };
      };

};
