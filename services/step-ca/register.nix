{lib, inputs, infra, vmname, vmconf,...}:

# TODO: patch the config file to use /run/secrets/ instead of /var/lib/step-ca in the path of the secrets
let 
    infralib = import "${inputs.self.outPath}/lib/infra" {inherit lib vmconf vmname;};
    reg = import "${inputs.self.outPath}/lib/registry/register.nix" {inherit inputs lib vmname infra vmconf;};
    secrets = {
        names = ["ca-password.key"];
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

