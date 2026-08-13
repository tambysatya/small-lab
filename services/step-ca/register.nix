{lib, inputs, infra, vmname, vmconf,...}:

# TODO: patch the config file to use /run/secrets/ instead of /var/lib/step-ca in the path of the secrets
let 
    infralib = import "${inputs.self.outPath}/lib/infra" {inherit lib vmconf vmname;};
    reg = import "${inputs.self.outPath}/lib/registry/register.nix" {inherit inputs lib vmname infra vmconf;};
    secrets = {
        names = ["ca-password.key" "intermediate_ca.key" "intermediate_ca.crt" "root_ca.crt"];
        owner = "step-ca";
        kind = {provider = "step";};
    };
in
{
    config = 
                (lib.mkMerge [
                    (reg.registerSecret "step-ca" "step-ca-keys" secrets)
                ]);
                    
}

