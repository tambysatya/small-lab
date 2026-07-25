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
            let settings=  infra.services.step-ca.settings or {};
            in {
              services.step-ca = lib.mkMerge 
              [
                {
                  enable = true;
                  settings = lib.mkDefault (builtins.fromJSON (builtins.readFile "${inputs.self.outPath}/secrets/plain/CA/config/ca.json"));
                  address = lib.mkDefault "${vmName}.${infra.domain}";
                  intermediatePasswordFile = "/var/lib/step-ca/ca-password";
                  openFirewall = lib.mkdefault true;
                }
                settings
                ];

              sops.secrets = secretLib.generateSecrets vmName "step-ca" ["step-ca.service"] secrets;
            };

}
