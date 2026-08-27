{lib, inputs, config, ...}:

let utils = import ./lib.nix {inherit lib inputs;};

    processService =
        _:
        {deployements, links,...}:
        utils.mergeAll (lib.concatMap (processLinks links) deployements);

    processLinks =
        {ldap, s3, postgres}:
        env:
        map (processLdap env) ldap 
        ++ map (processS3 env) s3
        ++ map (processPostgres env) postgres;

    ldaphosts = config.infra.services.openldap.deployements;
    s3hosts = config.infra.services.garage.deployements;
    dbhosts = config.infra.services.postgres.deployements;


    mkSharedSecret = env: hosts: secret:
        let ageuid = utils.ageUID env;
            mkHostSecret = host: {${utils.ageUID host}.sops=[secret];};
            dsts = lib.filter (name: name != ageuid) hosts;
        in utils.mergeAll 
                ([{${ageuid}.sops = [secret]; }] ++ map mkHostSecret dsts);

    processLdap =
        env: ldap:
        let secret = {inherit (ldap) filename owner reload mode;};
#            remote = {
#                ${ageuid}.proxy = {
#                    = confg.infra.deploy.network
#                    };
#            };
        in mkSharedSecret env ldaphosts secret; 
    processS3 = 
        env: access:
        let id = {filename=utils.s3_key_id access; inherit (access) owner reload; mode="0400";};
            key = {filename=utils.s3_key access; inherit (access) owner reload; mode="0400";};
        in utils.mergeAll 
                [(mkSharedSecret env s3hosts id)
                 (mkSharedSecret env s3hosts key)];
    processPostgres = 
        env: access: 
        let secret = {filename = utils.db_key access; inherit (access) owner reload; mode="0400";};
        in mkSharedSecret env dbhosts secret;
in {
    infra.deploy.systems = utils.mergeAll (lib.mapAttrsToList processService config.infra.services);
}
