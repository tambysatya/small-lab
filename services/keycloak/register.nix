{lib, inputs, pkgs, config, ...}:

let 
    hostname = "auth.${config.infra.topology.domain}";
    port = 8000;

    owner="root";
    reload = ["keycloak.service"];

in 
{

infra.services.keycloak = {
    users = [{name="keycloak"; uid=10002;}];
    store = {
        plain = [
            {filename="keycloak-initial-admin.key"; opensslSize = 64; opensslType = "base64";}
        ];
    };
    links = {
        postgres = [
            {database="keycloak"; inherit owner reload;}
        ];  
    };
    endpoints.tcp = [
        {inherit hostname port; needTLS=true;}
    ];
};

}

