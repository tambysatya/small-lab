{lib, inputs, config, ...}:

let
    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};

    processEndpoints = 
        endpoints@{tcp, udp,...}:
        processTCP tcp ++ processUDP udp;

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
          networkVM = {
                ${utils.ageUID env}.network.localEndpoints.tcp = [tcp];
          };
          containerVM = {
                
               ${utils.ageUID env}.network.localEndpoints.tcp =[tcp];
               ${env.host.vm}.network.containerEndpoints = [{inherit ageuid; endpoints.tcp=[tcp];}];
          };
        in
           {

                network.postgres = if proto == "postgres"
                                   then [{ip = ip; inherit env port;} ]
                                   else [];
                network.s3 = if proto == "s3"
                                   then [{ip = ip; inherit env port;}]
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
