{lib, inputs,  pkgs, config, ...}:

let 

    topology = config.infra.topology;
    hostname = "openldap.${topology.domain}";
    owner = "openldap";
    reload = ["openldap.service"];
in {

infra.services.openldap = {
    users = [{name="openldap"; uid=10004;}];
    endpoints.tcp = [
        {inherit hostname; port=389;}
        {inherit hostname; port=636;}
    ];
    files = {
        ldapSSHAs = [
            {filename="ldap-admin.key"; opensslSize=64; opensslType="base64";}
        ];
        sslCertificates = [
            {inherit hostname owner reload;}
        ];
    };
    persistent = [
        {path="/var/lib/openldap/data"; inherit owner reload;}
    ];
};

}

