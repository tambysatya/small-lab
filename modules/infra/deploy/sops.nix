{lib, inputs, config, ...}:

/* Generates an intermediate representation of the SOPS services to be generated */


let 
    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};
    processStore = 
        store@{passwords, sslCertificates,...}:
        let
           sopspass = map (args: {inherit (args) filename owner reload mode;}) passwords;
           sopscerts = lib.concatMap 
                            (cert@{hostname,...}:
                                let crt = "${hostname}.crt";
                                    key = "${hostname}.key";
                                    mkSops = name: {filename=name; inherit (cert) owner reload; mode="0400";};
                                in [(mkSops crt) (mkSops key)]) 
                            sslCertificates;
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


    processService = 
        srvname:
        let srv = config.infra.services.${srvname};
            fun = srv@{store, links, ...}: processStore store ++ processLinks links;
        in fun srv;

    sopsVM =
        vmname: vmconf: 
            let mkContainerSecret = srvname: {filename = "${utils.container_id vmname srvname}.key"; owner="root"; reload=["container@${srvname}.service"]; mode="0400";}; 
                containersSecrets = map mkContainerSecret vmconf.containers;
            in 
            {
                containers = utils.mergeAll (lib.map (srvname: {${utils.container_id vmname srvname}.sops = processService srvname;}) vmconf.containers);
                vms.${vmname}.sops = (lib.concatMap processService vmconf.services)
                                       ++ containersSecrets;
               
            }; 

in {
    infra.deploy = utils.mergeAll (lib.mapAttrsToList sopsVM config.infra.topology.vms);
}
