{lib, inputs, config, ...}:

let utils = import ./lib.nix {inherit lib inputs;};

    compileVMLinks =
        vmname: vmconf:
        utils.mergeAll [
            (utils.mergeAll (map (processServiceID vmname) vmconf.services)) 
            (utils.mergeAll (map (srvname: processServiceID (utils.container_id vmname srvname) srvname) vmconf.containers)) 
        ];
    processServiceID =
        ageuid: srvid:
        let srv = utils.serviceInfo config srvid;
        in utils.mergeAll (processLinks ageuid srv.links);

    processLinks =
        ageuid:
        {ldap, s3, postgres}:
        map (processLdap ageuid) ldap 
        ++ map (processS3 ageuid) s3
        ++ map (processPostgres ageuid) postgres;

    ldaphosts = map utils.ageUID config.infra.services.openldap.deployements;
    s3hosts = map utils.ageUID config.infra.services.garage.deployements;
    dbhosts = map utils.ageUID config.infra.services.postgres.deployements;


    mkSharedSecret = ageuid: hosts: secret:
        let mkHostSecret = host: {${host}.sops=[secret];};
            dsts = lib.filter (name: name != ageuid) hosts;
        in utils.mergeAll 
                ([{${ageuid}.sops = [secret]; }] ++ map mkHostSecret dsts);

    processLdap =
        ageuid: ldap:
        let secret = {inherit (ldap) filename owner reload mode;};
        in mkSharedSecret ageuid ldaphosts secret; 
    processS3 = 
        ageuid: access:
        let id = {filename=utils.s3_key_id access; inherit (access) owner reload; mode="0400";};
            key = {filename=utils.s3_key access; inherit (access) owner reload; mode="0400";};
        in utils.mergeAll 
                [(mkSharedSecret ageuid s3hosts id)
                 (mkSharedSecret ageuid s3hosts key)];
    processPostgres = 
        ageuid: access: 
        let secret = {filename = utils.db_key access; inherit (access) owner reload; mode="0400";};
        in mkSharedSecret ageuid dbhosts secret;
in {
    infra.deploy.systems = utils.mergeAll (lib.mapAttrsToList compileVMLinks config.infra.topology.vms);
}
