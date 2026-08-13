{inputs, lib, infra, registry, pkgs, ...}:

let
    gen = import ./gen-secrets.nix {inherit inputs lib infra pkgs;};
    utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};

    #unique identifier for a container
    get-ct-id = vmname: service: "ct-${vmname}-${service}";
    #all containers names (key = "ct-vmname-service")
    ctnames = lib.concatLists (
                    lib.mapAttrsToList (vmname: vmconf: 
                        lib.map (service: get-ct-id vmname service ) vmconf.containers) infra.vms);
    # all vm + containers identities
    gen_all_ages = lib.concatMapStringsSep "\n"
                            (name: gen.gen_age name)
                            ((builtins.attrNames infra.vms) ++ ctnames);



    # Gets the list of the register entries of all the services running natively (respect. within a container) on a vm
    getAllServices = vmname: lib.map (service: registry.services.${service}) (infra.vms.${vmname}.services);
    getAllContainers = vmname: lib.map (service: registry.services.${service}) (infra.vms.${vmname}.containers);

    processSSLSecrets = recipient: serviceslist:
        let sslsecrets = 
                (lib.filter (sec: sec.kind.provider == "openssl") 
                    (lib.concatMap (srv: builtins.attrValues srv.secrets) serviceslist));
        in ''
            # Generates the SSL secrets for ${recipient}
            ${lib.concatMapStringsSep "\n" gen.gen_openssl sslsecrets}

            # Encrypt them
            ${lib.concatMapStringsSep "\n" (gen.encrypt recipient) (lib.concatMap (sec: sec.names) sslsecrets) }
        '';

    /*
    processAllServices = serviceslist:
        ''
            ${processSSLSecrets serviceslist}
            ${processDBAccess serviceslist}
            ${processS3Access serviceslist}
        ''
    */
    
in
{
    test = lib.mapAttrs (vmname: _: processSSLSecrets vmname (getAllServices vmname)) (infra.vms);
    #test = lib.mapAttrs (vmname: _: processAllServices_ vmname (getAllServices vmname)) (infra.vms);
    main = pkgs.writeShellApplication {
            name = "gen-secrets";
            runtimeInputs = [
                pkgs.age
                pkgs.openssl
                pkgs.sops
            ];
            text = ''
                    set -x
                    ${gen_all_ages}

                    #SSL Secrets
                    ${lib.concatMapStringsSep "\n" (vmname: processSSLSecrets vmname (getAllServices vmname)) (builtins.attrNames infra.vms)}
            '';
    };
}
