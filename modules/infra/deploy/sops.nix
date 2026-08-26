{lib, inputs, config, ...}:

/* Generates an intermediate representation of the SOPS services to be generated */


let 
    utils = import ./lib {inherit lib inputs;};
    processStore = 
        store@{passwords, sslCertificates,...}:
        let
           sopspass = map (args: {inherit (args) filename owner reload mode;}) passwords;
           sopscerts = lib.concatMap utils.mkCertSops sslCertificates;
        in sopspass ++ sopscerts;
    processLinks = 
        links@{s3, postgres, ldap,...}:
            lib.concatMap utils.mkSopsS3 s3 ++ map utils.mkSopsDB postgres ++ map utils.mkSopsLDAP ldap;

    processEndpoints =  #TODO regroup endpoint managments ? To move easily from nginx to ha-proxy
        srvid:
        let srv = utils.serviceInfo config srvid;
            fun = args@{hostname,...}: mkCertSops {inherit hostname; owner="nginx"; reload=["nginx.service"]; };
        in lib.concatMap fun srv.endpoints.http;

    processService = 
        srvid:
        let srv = utils.serviceInfo config srvid;
            fun = srv@{store, links, ...}: processStore store ++ processLinks links;
        in fun srv;


    extractAllCerts =
        vmname: vmconf:
        let allServices = map (utils.serviceInfo config) (vmconf.services ++ vmconf.containers);
            allEndpoints = lib.concatMap (lib.attrByPath ["endpoints" "http"] null) allServices;
            allCerts = lib.concatMap (lib.attrByPath ["store" "sslCertificates"] null) allServices;
            allServicesNames = map (utils.serviceName config) vmconf.services;

        in allCerts ++ (map (ep: {inherit (ep) hostname; owner="nginx"; reload=["nginx.service"];}) allEndpoints);

    sopsVM =
        vmname: vmconf: 
            let mkContainerSecret = srvid: {filename = "${utils.container_id vmname srvid}.key"; owner="root"; reload=["container@${srvid}.service"]; mode="0400";}; 
                containersSecrets = map mkContainerSecret vmconf.containers;

                s3hosts = map utils.ageKeyFromDeployementEnvironment config.infra.services.garage.deployement; 
                dbhosts = map utils.ageKeyFromDeployementEnvironment config.infra.services.postgres.deployement; 
            in 
            {
                containers = utils.mergeAll (lib.map (srvid: {${utils.container_id vmname srvid}.sops = processService srvid;}) vmconf.containers);
                vms.${vmname} = {
                    sops = (lib.concatMap processService vmconf.services)
                         ++ (lib.concatMap processEndpoints vmconf.services)
                         ++ (lib.concatMap processEndpoints vmconf.containers)
                         ++ containersSecrets;
                    sslCertificates = extractAllCerts vmname vmconf;
            } ;
               

in {
    infra.deploy = utils.mergeAll (lib.mapAttrsToList sopsVM config.infra.topology.vms);
}
