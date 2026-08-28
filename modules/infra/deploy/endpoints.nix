{lib, inputs, config, ...}:

let
    utils = import ./lib.nix {inherit lib inputs;};

    processEndpoints = 
        endpoints@{tcp, udp,...}:
        processTCP tcp ++ processUDP udp;

    mkTLSProxy = 
    backend: tcp@{hostname, port, proto, proxyExtraConfig,...}:
    {
        frontend.${hostname} = {
            listen = "0.0.0.0"; 
            mode = "http";
            port = 443;
            extraConf = proxyExtraConfig;
        };
        backend.${hostname} = [{ 
           ip=backend;
           mode = "http";
           port = port;
        }];
    };

    processUDP = throw "UDP not implemented yet";
    processTCP = 
        env:
        tcp@{hostname, port, proto, needTLS, proxyExtraConfig}:
        let
          cfg = config.infra.deploy.systems;
          ageuid = utils.ageUID env; 
          ip = if env.type == "vm"
                    then cfg.${ageuid}.ip
                    else cfg.${env.host.vm}.ip;
          networkVM = if needTLS then {
                ${utils.ageUID env}.proxy = mkTLSProxy "localhost" tcp;
          } else {};
          containerVM = if needTLS 
            then {
               ${env.host.vm}.proxy = let containerip = config.infra.deploy.systems.${utils.ageUID env}.ip;
                                      in mkTLSProxy containerip tcp;
#                
            }
            else {
               ${env.host.vm}.proxy = {
                    frontend.${hostname} = {
                        mode = if proto == "http" || proto == "https"
                            then "http"
                            else "tcp";
                        port = port;
                        extraConf = proxyExtraConfig;
                        listen = "0.0.0.0";
                    };
                    backend.${hostname} = [{
                        ip = utils.envIP config env;
                        mode = if proto == "http" || proto == "https"
                            then "http"
                            else "tcp";
                        port = port;
                    }];
               };
            };

        in
           {

                network.postgres = if proto == "postgres"
                                   then [{inherit env port;} ]
                                   else [];
                network.s3 = if proto == "s3"
                                   then [{inherit env port;}]
                                   else [];
                systems = if env.type == "vm" then networkVM else containerVM;
           };        
    processService = 
        srv@{deployements, endpoints,...}:
        let allTCP =
                lib.concatMap
                    (env: map (processTCP env) endpoints.tcp)
                    deployements;
            allUDP =
                lib.concatMap
                    (env: map (processUDP env) endpoints.udp)
                    deployements;
        in utils.mergeAll allTCP; #(allTCP ++ allUDP);
in {
    config.infra.deploy = utils.mergeAll (lib.mapAttrsToList (srvname: srv: processService srv) config.infra.services);
}
