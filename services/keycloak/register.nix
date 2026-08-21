{lib, inputs, pkgs, config, ...}:

let 
    infra = config.infra;
    hostname = "auth.${infra.domain}";
    port = 8000;

    owner="root";
    reload = ["keycloak.service"];

in 
{

registry.services.keycloak = {
    users = [{name="keycloak"; uid=10002;}];
    files = {
        plain = [
            {filename="keycloak-initial-admin.key"; opensslSize = 64; opensslType = "base64";}
        ];
        postgres = [
            {database="keycloak"; inherit owner reload;}
        ];  
    };
    endpoints.http = [
        {inherit hostname port;}
    ];
};

}

