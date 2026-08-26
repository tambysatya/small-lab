{lib, inputs, config, ...}:

let utils = import ./lib.nix {inherit lib inputs;};

    processStore = 
        store@{passwords, sslCertificates,...}:
            utils.mergeAll 
                (map processPasswords passwords
                ++ map processCertificates sslCertificates);
    processPasswords =
        pass: 
        {
            sops = [{inherit (pass) filename owner reload mode;}];
        };
    processCertificates = 
        cert@{hostname,...}:
        let crt = "${hostname}.crt";
            key = "${hostname}.key";
        in {
            sops = [{filename=crt; mode="0400"; inherit (cert) owner reload;}
                    {filename=key; mode="0400"; inherit (cert) owner reload;}];
            sslCertificates = [cert];
        };
    
    processServiceID =
        srvid:
        let service = utils.serviceInfo config srvid;
            stepcasecretnames = ["intermediate_ca_key" "ca-password.key"];
            stepcasecrets = map (filename: {inherit filename; owner="root"; mode="0400"; reload=["step-ca.service"];}) stepcasecretnames;
            additionalsecrets = if utils.serviceName config srvid == "step-ca" then {sops = stepcasecrets;} else {};

        in utils.mergeAll 
            [(processStore service.store) 
             additionalsecrets];
    
    compileVMStore = 
        vmname: vmconf:
        let containerssops =
                map 
                    (srvid: {
                        ${utils.container_id vmname srvid} = processServiceID srvid;
                    }) vmconf.containers;
        in {
            ${vmname} = utils.mergeAll (map processServiceID vmconf.services);
        } // utils.mergeAll containerssops;
in
{
    infra.deploy.systems = utils.mergeAll (lib.mapAttrsToList compileVMStore config.infra.topology.vms);
}
