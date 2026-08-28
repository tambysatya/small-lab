{lib, inputs, infra, registry, vmname, vmconf,...}:
let 

    infralib = import "${inputs.self.outPath}/lib/infra" {inherit lib vmconf vmname;};
    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit lib infra inputs registry;};

    /* TODO secrets + sops service should be handled manually here 
        STEP secrets have a very specific generation procedure (using step ca init) that is used once. Therefore,
        there will not be an API way to declare them
    */
in {

/* TODO (see above)
    sops.secrets = {

    };
*/

    config = lib.mkIf 
                (infralib.runsService "step-ca")
                    {
                        services.step-ca = {
                            enable = true;
                            address = infra.caURL;
                            port = infra.caPort;
                            openFirewall = true;
                            intermediatePasswordFile = "/run/secrets/ca-password.key";
                            settings = builtins.fromJSON (builtins.readFile "${infra.flakePath}/${vars.git}/ca.json"); 
                        };
                    };
        
}
