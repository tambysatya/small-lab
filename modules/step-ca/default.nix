{lib, inputs, infra, vmname, vmconf,...}:

{

    config = lib.mkIf 
                (builtins.elem "step-ca" vmconf.services) 
                    {
                        services.step-ca = {
                            enable = true;
                            address = infra.caURL;
                            port = infra.caPort;
                            openFirewall = true;
                            intermediatePasswordFile = "/var/lib/step-ca/ca-password";
                            settings = builtins.fromJSON (builtins.readFile "${infra.secrets-path}/plain/CA/config/ca.json"); 
                        };
                    };
        
}
