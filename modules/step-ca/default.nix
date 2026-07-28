{lib, inputs, infra, vmname, vmconf,...}:

{

    config = lib.mkIf 
                (builtins.elem "step-ca" vmconf.services) 
                    {
                        services.step-ca = {
                            enable = true;
                            address = infra.caURL;
                            port = 8443;
                            openFirewall = false;
                            intermediatePasswordFile = "/var/lib/step-ca/password";
                            settings = builtins.fromJSON (builtins.readFile ../secrets/plain/CA/config/ca.json); 
                        };
                    };
        
}
