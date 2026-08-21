{lib, inputs, pkgs, config, ...}:

let 
    infra = config.infra;
    reg = import "${inputs.self.outPath}/lib/registry/register.nix" {inherit inputs lib infra;};

    hostname = "auth.${infra.domain}";
    port = 8000;

    owner="root";
    reload = ["keycloak.service"];

in 
{

registry.services.keycloak = {
    users = [{name="keycloak"; uid=10002;}];
    files.postgresAccesses = [
        {database="keycloak"; inherit owner reload;}
    ];
    endpoints.http = [
        {inherit hostname port;}
    ];
};

}

