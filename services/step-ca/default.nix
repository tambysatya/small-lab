{lib, inputs, infra, registry, vmname, vmconf,...}:
let 

    infralib = import "${inputs.self.outPath}/lib/infra" {inherit lib vmconf vmname;};
    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit lib infra inputs registry;};
in {

    config = lib.mkIf 
                (infralib.runsService "step-ca")
                    {
                        services.step-ca = {
                            enable = true;
                            address = infra.caURL;
                            port = infra.caPort;
                            openFirewall = true;
                            intermediatePasswordFile = "/var/lib/step-ca/ca-password";
                            settings = builtins.fromJSON (builtins.readFile "${infra.flakePath}/${vars.git}/ca.json"); 
                        };
                    };
        
}
