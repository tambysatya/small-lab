{lib, inputs, infra, vmname, vmconf,...}:

let 
  reg = import ./infra-services/lib/register.nix {inherit lib inputs infra vmname;};
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

    config = lib.mkIf 
                (builtins.elem "step-ca" vmconf.services) 
                (lib.mkMerge [
                    (reg.registerSecrets "step-ca" "step-ca" ["step-ca.service"] secrets)
                    {
                        services.step-ca = {
                            enable = true;
                            address = "identity.local.lphi.umontpellier.fr";
                            port = 8443;
                            openFirewall = false;
                            intermediatePasswordFile = "/var/lib/step-ca/password";
                            settings = builtins.fromJSON (builtins.readFile ../secrets/plain/CA/config/ca.json); 
                        };
                    }
                ]);
                
        
}
