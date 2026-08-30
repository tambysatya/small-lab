{lib, inputs, pkgs, config, path, ...}:

let

    utils = import ../deploy/lib.nix {inherit inputs lib;};
    processSystem =
        envuid:
        deploy@{env, ip, proxy, sops, sslCertificates, storage, users}:
        {
            ${envuid}.config = utils.mergeAll [
                        (processSops sops)
                     ];
        } 
        //
        (if env.type == "container"
            then {
                ${env.host.vm}.config.sops.secrets."${env.host.container}.key" = {
                    sopsFile = "${path}/.secrets/enc/${env.host.container}.key";
                    format = "binary";
                    restartUnits = ["container@${env.host.container}.service"];
                    owner = "root";
                };
            }
            else {});

    processSops =
        sops:
        let process =
                {filename, owner, reload, mode}:
                {
                    sops.secrets."${filename}" = {
                        sopsFile = "${path}/.secrets/enc/${filename}.enc";
                        format = "binary";
                        restartUnits = reload;
                        inherit owner mode;
                    };
                };
            initSops = {sops.age.keyFile = "/var/lib/sops-nix/key.txt";};
        in utils.mergeAll ([initSops] ++ map process sops);

in

{
    imports = [./options ./step.nix];
    #infra.outputs = utils.mergeAll (lib.mapAttrsToList processSystem config.infra.deploy.systems);
}
