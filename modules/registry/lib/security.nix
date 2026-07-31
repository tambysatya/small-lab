{inputs, lib, infra, vmname,  ...}:
    

/* Basic security management: Secrets, TLS certificates and reverse proxys */

let 

    # Generate the sops options for an attrset of secrets (same owner, same reloadUnit

    generateSecret = 
      servicename: secretname: secret:
          let secretFile = "${infra.secrets-path}/encrypted/${vmname}-${secretname}.enc";
          in lib.mkMerge [
          {

            sops.age.keyFile = "/var/lib/sops-nix/key.txt";
            sops.secrets."${secretname}" = {
                sopsFile = secretFile;
                path = secret.path or "/run/secrets/${secretname}";
                format = "binary";
                owner = secret.owner or "root";
                restartUnits = secret.reload;
                mode = secret.mode or "0400";
             };
          }
         ];

   /* Generates the secret and the auto-refresh service for a given certificate.
      registerCertificate : vmname -> owner -> serviceunit -> NixosConfig

      - the servicename (different from the unit) is of type "servicetype".
        It will be used to have a different behavior regarding how the service is deployed
        (e.g. if deployed within a nixos-container, the secret will also be bindmount)
      - the encrypted secret must have name certname.{crt,key}.enc
      - the secret will be stored in /var/lib/owner/certname.{crt,key}
      - the reload units are set to [ serviceunit ]
    */

    generateCertificate =
       servicename: certname: sslcert:
          lib.mkMerge [
          {
                services.step-renew = {
                    enable = true;
                    caURL = "${infra.caURL}:${lib.toString infra.caPort}";
                    caFingerprint = builtins.readFile "${infra.secrets-path}/plain/CA/fingerprint";
                    certs."${certname}" = sslcert;
                };
           }];

    generateReverseProxy =
        fronthost: backhost: 
        let

        in lib.mkMerge [
            {
                networking.firewall.allowedTCPPorts = [80 443];
                services.nginx = {
                    enable = true;
                    virtualHosts."${fronthost}" ={
                        sslCertificate = "/run/secrets/${fronthost}.crt";
                        sslCertificateKey = "/run/secrets/${fronthost}.key";
                        forceSSL = true;

                        locations."/" = {
                            proxyPass = backhost;
                            extraConfig = ''
                                  proxy_set_header Host $host;
                                  proxy_set_header X-Forwarded-Host $host;
                                  proxy_set_header X-Forwarded-Proto $scheme;
                                  proxy_set_header X-Forwarded-Port $server_port;
                                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

                              '';

                        };
                    };
                };
            }
            ];

in {
    inherit generateSecret generateCertificate generateReverseProxy;
}
