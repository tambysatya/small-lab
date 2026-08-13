{lib, inputs, infra, vmname, vmconf,...}:

let 
    infralib = import "${inputs.self.outPath}/lib/infra" {inherit lib vmconf vmname;};
    reg = import "${inputs.self.outPath}/lib/registry/register.nix" {inherit inputs lib vmname infra vmconf;};
    STEPPATH="/var/lib/step-ca";
    secrets = {
       # "ca.json" = {
       #     path = "${STEPPATH}/config";
       # };
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
in
{
    config = 
                (lib.mkMerge [
                    (reg.registerSecrets "step-ca" "step-ca" ["step-ca.service"] secrets)
                ]);
                    
}

