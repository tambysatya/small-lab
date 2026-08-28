{lib, inputs, config, ...}:

let utils = import ./lib.nix {inherit lib inputs;};

    processStore = 
        store@{passwords, sslCertificates,...}:
        env:
            utils.mergeAll 
                (map (processPasswords env) passwords
                ++ map (processCertificates env) sslCertificates);
    processPasswords =
        env:
        pass: 
        {
            ${utils.ageUID env}.sops = [{inherit (pass) filename owner reload mode;}];
        };
    processCertificates = 
        env:
        cert@{hostname,...}:
        let crt = "${hostname}.crt";
            key = "${hostname}.key";
        in {
            ${utils.ageUID env} = {
                sops = [{filename=crt; mode="0400"; inherit (cert) owner reload;}
                        {filename=key; mode="0400"; inherit (cert) owner reload;}];
                sslCertificates = [cert];
            };
        };


    processService = 
        srvname: {deployements, store,...}:
        let stepcasecretnames = ["intermediate_ca_key" "ca-password.key"];
            stepcasecrets = map (filename: {inherit filename; owner="root"; mode="0400"; reload=["step-ca.service"];}) stepcasecretnames;
            additionalsecrets = env: {${utils.ageUID env}.sops = stepcasecrets;};
        in
        utils.mergeAll (map (processStore store) deployements ++ (if srvname == "step-ca" then map additionalsecrets deployements else []));

in
{
    infra.deploy.systems = utils.mergeAll (lib.mapAttrsToList processService config.infra.services);
}
