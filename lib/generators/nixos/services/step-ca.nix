{lib, inputs, ...}:

let 
  STEPPATH="/var/lib/step-ca";
  secretLib = import ./secrets.nix {inherit lib inputs;};
  secrets = {
    "ca.json" = {
        path = "${STEPPATH}/config";
    };
    "ca-password" = {
        path = "${STEPPATH}/ca-password";
    };
    "intermediate_ca_key" = {
        path = "${STEPPATH}/secrets/intermediate_ca_key";
    };
    "intermediate_ca.crt" = {
        path = "${STEPPATH}/certs/intermediate_ca.crt";
        mode = "0444";
    };
    "root_ca.crt" = {
        path = "${STEPPATH}/certs/root_ca.crt";
        mode = "0444";
    };
  };
in {

generator = infra: vmName:
            let service =  infra.services.step-ca or {};
                ssl = service.sslIdentity;
            in {
              services.step-ca = lib.mkMerge 
              [
                {
                  enable = true;
                  settings = lib.mkDefault (builtins.fromJSON (builtins.readFile ../../../secrets/plain/CA/confi/ca.json));
                  address = lib.mkDefault "${vmName}.${infra.domain}";
                  intermediatePasswordFile = "/var/lib/step-ca/ca-password";
                  openFirewall = lib.mkdefault true;
                }
                (service.settings or {})
                ];

              sops.secrets = secretLib.generateSecrets vmName "step-ca" ["step-ca.service"] secrets;
            };

}
