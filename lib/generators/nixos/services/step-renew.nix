{lib, ...}:



{

  /* Generates the secret and the auto-refresh service for a given certificate.
     registerCertificate : vmName -> owner -> serviceUnit -> NixosConfig

     - the encrypted secret must have name certName.{crt,key}.enc
     - the secret will be stored in /var/lib/owner/certName.{crt,key}
     - the reload units are set to [ serviceUnit ]
  */
     
  generateCertificates =
    infra: vmName: owner: serviceUnit: certName:
      {inputs,config,...}:
        let 
            basepath = "/var/lib/${owner}/${certName}";
            secretlib = import ./secrets.nix {inherit inputs lib;}; 
            unit = serviceUnit;
            secrets = {
                        "${certName}.crt" = {
                            path = config.services.step-renew.certs."${certName}".cert;
                        };
                        "${certName}.key" = {
                            path = config.services.step-renew.certs."${certName}".key;
                        };
                      };
        in{
          imports = [(secretlib.generateSecrets vmName owner [unit] secrets)];
          services.step-renew.certs."${certName}" = {
            cert = "${basepath}.crt";
            key = "${basepath}.key";
            reload = [serviceUnit];
          };
        };

}
