{lib, inputs, config, ...}:

/* Generates an intermediate representation of the SOPS services to be generated */


let 
    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};

    mkCertSops = 
        cert@{hostname,owner, reload,...}:
        let crt = "${hostname}.crt";
            key = "${hostname}.key";
            mkSops = name: {filename=name; inherit owner reload; mode="0400";};
        in [(mkSops crt) (mkSops key)];
    processStore = 
        store@{passwords, sslCertificates,...}:
        let
           sopspass = map (args: {inherit (args) filename owner reload mode;}) passwords;
           sopscerts = lib.concatMap mkCertSops sslCertificates;
        in sopspass ++ sopscerts;
    processLinks = 
        links@{s3, postgres, ldap,...}:
        let
            mkSopsS3 = access:
                            [
                                {filename=utils.s3_key_id access; inherit (access) owner reload; mode="0400";}
                                {filename=utils.s3_key access; inherit (access) owner reload; mode="0400";}
                            ];
            mkSopsDB = access: {filename=utils.db_key access; inherit (access) owner reload; mode="0400";};
            mkSopsLDAP = access: {inherit (access) filename owner reload; mode = "0400";};
        in lib.concatMap mkSopsS3 s3 ++ map mkSopsDB postgres ++ map mkSopsLDAP ldap;

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

    sopsVM =
        vmname: vmconf: 
            let mkContainerSecret = srvid: {filename = "${utils.container_id vmname srvid}.key"; owner="root"; reload=["container@${srvid}.service"]; mode="0400";}; 
                containersSecrets = map mkContainerSecret vmconf.containers;
            in 
            {
                containers = utils.mergeAll (lib.map (srvid: {${utils.container_id vmname srvid}.sops = processService srvid;}) vmconf.containers);
                vms.${vmname}.sops = (lib.concatMap processService vmconf.services)
                                       ++ (lib.concatMap processEndpoints vmconf.services)
                                       ++ (lib.concatMap processEndpoints vmconf.containers)
                                       ++ containersSecrets;
               
            }; 

in {
    infra.deploy = utils.mergeAll (lib.mapAttrsToList sopsVM config.infra.topology.vms);
}
