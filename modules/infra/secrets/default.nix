{lib, inputs, config,...}:
let

    infralib = import "${inputs.self.outPath}/lib" {inherit lib inputs;};

    processSecret = 
        deployements: 
        secrettype:
        secret: 
        let additionalRecipients = # adding the hosts of the requested service (to create the access). Note: no need to add openldap since the file will be hashed
        if secrettype == "postgres" then
            map infralib.ageKeyFromDeployementEnvironment config.infra.services.postgres.deployements
        else if secrettype == "s3" then
            map infralib.ageKeyFromDeployementEnvironment config.infra.services.garage.deployements 
        else [];
        in
        lib.mkIf (deployements != [])
        {
            type=secrettype;
            content=secret;
            recipients = lib.unique (additionalRecipients ++ map infralib.ageKeyFromDeployementEnvironment deployements);
        };

    serviceSecrets = 
        srvname: {deployements, links, store, endpoints, ...}: 
        let
            plain = store.plain;
            passwords = store.passwords;
            certs = store.sslCertificates ++ endpoints.http;

            postgres = links.postgres;
            ldap = links.ldap;
            s3 = links.s3;
        in 
            map (processSecret deployements "plain") plain
        ++  map (processSecret deployements "password") passwords
        ++  map (processSecret deployements "sslCertificates") certs
        ++  map (processSecret deployements "postgres") postgres
        ++  map (processSecret deployements "ldapssha") ldap
        ++  map (processSecret deployements "s3") s3
        ++  (if srvname == "step-ca"
                then [(processSecret deployements "step-ca" null)] 
                else []);
    allSecrets= lib.mapAttrsToList serviceSecrets config.infra.services;
    
    ageIdentities =
        srvname: {deployements,...}:
            map infralib.ageKeyFromDeployementEnvironment deployements;
            
in {
    imports = [./options];
    config.infra.secrets = { 
        identities = lib.unique (lib.concatLists (lib.mapAttrsToList ageIdentities config.infra.services));
        allSecrets = lib.unique (lib.concatLists allSecrets);
    };
}
