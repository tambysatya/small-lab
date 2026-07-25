{lib,config,...}:

let 
  STEPPATH="/var/lib/step-ca";
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
    "intermediate_ca" = {
        path = "${STEPPATH}/certs/intermediate_ca.crt";
        mode = "0444";
    };
    "root_ca" = {
        path = "${STEPPATH}/certs/root_ca.crt";
        mode = "0444";
    };
  };
in {

generator = infra: vmName:
            let service =  infra.vmServices.step-ca;
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
                service.settings
              ];
            };

}
