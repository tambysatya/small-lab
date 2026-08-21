{lib, inputs, config,...}:

let 
    infra = config.infra;
    secrets = {
        names = ["ca-password.key"  "intermediate_ca_key"];
        owner = "step-ca";
        kind = {provider = "step";};
    };
    hostname = "ca.${infra.domain}";
    port = infra.caPort;
in
{
registry.services.step-ca = {
    users = [{name="keycloak"; uid=10006;}];
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

