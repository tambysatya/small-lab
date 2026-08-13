{lib, inputs, infra, vmname, vmconf,...}:
let 
    infralib = import "${inputs.self.outPath}/lib/infra" {inherit lib vmconf vmname;};
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
                            settings = builtins.fromJSON (builtins.readFile "${infra.secretsPath}/plain/CA/config/ca.json"); 
                        };
                    };
        
}
