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
        let ageuid = utils.envUID env;
            mkHostSecret = host: {${utils.envUID host}.secrets=[secret];};
            dsts = lib.filter (name: name != ageuid) hosts;
        in utils.mergeAll 
                ([{${ageuid}.secrets = [secret]; }] ++ map mkHostSecret dsts);

    mkProxy =
        env: proxyname: port: hostenvs: mode:
        let proxyVM =
            {
                ${utils.envUID env}.proxy = {
                        frontend.${proxyname}= {
                            inherit mode;
                            port = port;
                            listen = if utils.hostHasContainers config env
                                     then "192.168.1.1"
                                     else "127.0.0.1";
                        };
                        backend.${proxyname}= 
                            let genBackend = hostenv:
                                    {
                                        inherit mode;
                                        ip = utils.envHostIP config hostenv;
                                        port = port;
                                    };
                            in map genBackend hostenvs;
                    };
            };
            proxyContainer = {
                 ${utils.envUID env}.proxy.defaultProxy = config.infra.deploy.systems.${env.host.vm}.ip;
                 ${env.host.vm}.proxy = {
                        frontend.${proxyname} = {
                            listen = "192.168.1.1";
                            port = port;
                            inherit mode;
                        };
                        backend.${proxyname} = 
                            let genBackend = hostenv:
                                    {
                                        inherit mode;
                                        ip = utils.envHostIP config hostenv;
                                        port = port;
                                    };
                            in map genBackend hostenvs;
                    };               
            };
        in if env.type == "vm" then proxyVM else proxyContainer;

    processLdap =
        env: ldap:
        let secret = {inherit (ldap) filename owner reload mode;};
        in mkSharedSecret env ldaphosts secret // mkProxy env "ldap" 636 ldaphosts "tcp"; 
    processS3 = 
        env: access:
        let id = {filename=utils.s3_key_id access; inherit (access) owner; mode="0400";};
            key = {filename=utils.s3_key access; inherit (access) owner; mode="0400";};

        in utils.mergeAll 
                [(mkSharedSecret env s3hosts id)
                 (mkSharedSecret env s3hosts key)
                 (mkProxy env "s3" 443 s3hosts "http")];
    processPostgres = 
        env: access: 
        let secret = {filename = utils.db_key access; inherit (access) owner; mode="0400";};
        in mkSharedSecret env dbhosts secret //
           mkProxy env "postgres" 5432 dbhosts "tcp";
in {
    infra.deploy.systems = utils.mergeAll (lib.mapAttrsToList processService config.infra.services);
}
