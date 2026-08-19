{lib, inputs, infra,...}:

# TODO: patch the config file to use /run/secrets/ instead of /var/lib/step-ca in the path of the secrets
let 
    reg = import "${inputs.self.outPath}/lib/registry/register.nix" {inherit inputs lib infra;};
    secrets = {
        names = ["ca-password.key"  "intermediate_ca_key"];
        owner = "step-ca";
        kind = {provider = "step";};
    };
in
{
    config = 
                (lib.mkMerge [
                    (reg.registerSecret "step-ca" "step-ca-keys" secrets)
                    (reg.registerUser "step-ca" "step-ca" 10006)
                ]);
                    
}

