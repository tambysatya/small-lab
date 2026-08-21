{lib, inputs, config,...}:

let 
    topology = config.infra.topology;
    secrets = {
        names = ["ca-password.key"  "intermediate_ca_key"];
        owner = "step-ca";
        kind = {provider = "step";};
    };
    hostname = "ca.${topology.domain}";
    port = 8443;
in
{
infra.services.step-ca = {
    users = [{name="step-ca"; uid=10006;}];
    endpoints.tcp = [
        {inherit hostname port;}
    ];
};
/*
    config.registry = 
                (lib.mkMerge [
                    (reg.registerSecret "step-ca" "step-ca-keys" secrets)
                    (reg.registerUser "step-ca" "step-ca" 10006)
                ]);
*/                    
}

