{inputs, lib, infra, registry, pkgs, ...}:

let

    utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};
    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit inputs lib infra pkgs registry;};
    age = import ./age.nix {inherit inputs lib infra pkgs registry;};
    pvds = import ./providers {inherit inputs lib infra pkgs registry;};

    #unique identifier for a container
    #all containers names (key = "ct-vmname-service")
    ctnames = lib.concatLists (
                    lib.mapAttrsToList (vmname: vmconf: 
                        lib.map (service: vars.container_id vmname service ) vmconf.containers) infra.vms);
    
    # all vm + containers identities
    all_names = builtins.attrNames infra.vms ++ ctnames;

    # generates all the identity keys
    gen_all_ages = lib.concatMapStringsSep "\n"
                            (name: age.gen_age name)
                            all_names;

    encrypt_containers_age = lib.concatMapStringsSep "\n"
                                (vmname:
                                    lib.concatMapStringsSep "\n"
                                        (servicename:
                                            age.encrypt_key vmname "${vars.container_id vmname servicename}.key")
                                        infra.vms.${vmname}.containers)
                                (builtins.attrNames infra.vms);



    # Gets the list of the register entries of all the services running natively (respect. within a container) on a vm
    # VMName -> [ServiceEntry]
    getNativeServices = vmname: lib.map (service: registry.services.${service}) (infra.vms.${vmname}.services);
    getContainersServices = vmname: lib.map (service: registry.services.${service}) (infra.vms.${vmname}.containers);

    # allServices : Map VMName [ServiceEntry] for the natives services
    allServices = lib.mapAttrs (vmname: _: getNativeServices vmname) infra.vms;
    # Map VMName [ServiceEntry] (but for the containers)
    allContainersInVM = lib.mapAttrs (vmname: _: getContainersServices vmname) infra.vms;

    #Map ContainerName [ServiceEntry]
    allContainers = utils.mergeAll 
                        (lib.mapAttrsToList
                            (vmname: vmconf:
                                utils.mergeAll 
                                    (lib.map 
                                        (service: {${vars.container_id vmname service} = [registry.services.${service}];})
                                        vmconf.containers))
                            infra.vms);

    applyProvider =
        natives: containers:
        provider: 
        ''
            ${lib.concatStringsSep "\n" 
                (lib.mapAttrsToList
                    (vmname: serviceslist:
                        provider vmname serviceslist)
                    (utils.mergeAll [natives containers]))}
        '';


in
{
    #test = lib.mapAttrs (vmname: _: processAllServices_ vmname (getAllServices vmname)) (infra.vms);
    test = allContainers;
    main = pkgs.writeShellApplication {
            name = "gen-secrets";
            runtimeInputs = [
                pkgs.age
                pkgs.openssl
                pkgs.openldap
                pkgs.sops
                pkgs.step-cli
            ];
            # For each kind of secret, we generate for the services running natively AND running within a container
            text = ''
                    ${gen_all_ages}
                    ${encrypt_containers_age}

                    ${pvds.bootstrap_step_ca}
                    ${pvds.bootstrap_ldap}
                    
                    echo "[RECALL: KEYCLOAK INITIAL ADMIN PASSWORD IS VERSIONNED. Login and change it !]"
                    ${lib.getExe pkgs.openssl} rand -base64 64 > ${vars.git}/keycloak-initial-admin

                    # Password Secrets
                    ${applyProvider allServices allContainers pvds.processPasswordSecrets}

                    # S3Secrets
                    ${applyProvider allServices allContainers pvds.processS3Secrets}

                    # DBSecrets
                    ${applyProvider allServices allContainers pvds.processDBSecrets}

                    # Certificates
                    ${applyProvider allServices allContainers pvds.processSSLCertificates}

                    # Endpoints
                    # Applied on allContainersInVM insted of allContainers because the certificate
                    # is encrypted for the host and not for the container
                    ${applyProvider allServices allContainersInVM pvds.processHTTPEndpoints} 

                    #Tokens generation for the secret provisioner
                    ${lib.concatStringsSep "\n"
                        (lib.map age.gen_age_token (builtins.attrNames infra.vms))}
                    # Certificate for the secret-provisioner
                    mkdir -p ${infra.secretsPath}/provisioner/ssl
                    ${pvds.gen_ssl_certificate "vm-provisioning.${infra.domain}"}
                    mv ${vars.plain}/vm-provisioning.${infra.domain}.* ${infra.secretsPath}/provisioner/ssl/

            '';
    };
}
