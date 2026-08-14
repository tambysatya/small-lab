{inputs, lib, infra, vmname,  ...}:
    

/* Basic security management: Secrets, TLS certificates and reverse proxys */

let 

    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit lib infra inputs;};
    # Generate the sops options for an attrset of secrets (same owner, same reloadUnit
    generateSecret = 
      servicename: secretname: secret:
          let secretFile = "${vars.enc}/${vmname}-${secretname}.enc";
          in lib.mkMerge [
          {

            sops.age.keyFile = "/var/lib/sops-nix/key.txt";
            sops.secrets."${secretname}" = {
                sopsFile = secretFile;
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
       let
            secrets = {
                "${certname}.crt" = {owner = sslcert.owner; reload=sslcert.reload;};
                "${certname}.key" = {owner = sslcert.owner; reload=sslcert.reload;};
            };
       in
          lib.mkMerge [
            (lib.mkMerge (lib.mapAttrsToList 
                            (generateSecret servicename)
                            secrets))
          {
                services.step-renew = {
                    enable = true;
                    caURL = "${infra.caURL}:${lib.toString infra.caPort}";
                    caFingerprint = builtins.readFile "${vars.git}/fingerprint";
                    certs."${certname}" = {cert = "/run/secrets/${certname}.crt"; key="/run/secrets/${certname}.key";};
                };
           }];

    generateReverseProxy =
        {fronthost, backhost, extraNginxConfig ? {}}: 
        let

        in lib.mkMerge [
            (generateCertificate "nginx" fronthost 
                {
                    reload = ["nginx.service"];
                    owner = "nginx";
                })
            {
                networking.firewall.allowedTCPPorts = [80 443];
                services.nginx = lib.mkMerge [
                    {
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

                                  '' ;

                            };
                        };
                    }
                    extraNginxConfig];
            }
            ];

in {
    inherit generateSecret generateCertificate generateReverseProxy;
}
