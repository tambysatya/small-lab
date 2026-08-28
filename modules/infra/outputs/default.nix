{lib, inputs, pkgs, config, path, ...}:

let

    utils = import ../deploy/lib.nix {inherit inputs lib;};
    processSystem =
        ageuid:
        deploy@{env, ip, proxy, sops, sslCertificates, storage, users}:
        {
            config = utils.mergeAll [
                        (processSops sops)
                        #(processStepRenew sslCertifcates)
                        #(processStorage storage)
                        #(processUsers users)
                     ];
        };

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
    imports = [./options];
    infra.outputs = lib.mapAttrs processSystem config.infra.deploy.systems;
}
