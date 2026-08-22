{lib, inputs, config,...}:
let

    infralib = import "${inputs.self.outPath}/lib" {inherit lib inputs;};

    processSecret = 
        deployements: 
        secrettype:
        secret: 
        {
            type=secrettype;
            content=secret;
            recipients = map infralib.ageKeyFromDeployementEnvironment deployements;
        };
    processService = 
        srvname: {deployements, links, files, ...}: 
        let
            plain = files.plain;
            passwords = files.passwords;
            certs = files.sslCertificates;

            postgres = links.postgres;
            ldap = links.ldapSSHAs;
            s3 = links.s3;
        in 
            map (processSecret deployements "plain") plain
        #++  map (processSecret deployements "password") passwords
        ++  map (processSecret deployements "sslCertificates") certs
        ++  map (processSecret deployements "postgres") postgres
        ++  map (processSecret deployements "ldapssha") ldap
        ++  map (processSecret deployements "s3") s3
        ++  (if srvname == "step-ca"
                then [(processSecret deployements "step-ca" null)] 
                else []);
    allSecrets= (lib.mapAttrsToList processService (config.infra.services));
in {
    imports = [./options];
    config.infra.secrets = 
        lib.concatLists (lib.mapAttrsToList processService (config.infra.services));
}
