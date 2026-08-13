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
                                        (service: {${get-ct-id vmname service} = [registry.services.${service}];})
                                        vmconf.containers))
                            infra.vms);



    processPasswordSecrets = recipient: serviceslist:
        let pwsecrets = 
                (lib.filter (sec: sec.kind.provider == "openssl") 
                    (lib.concatMap (srv: builtins.attrValues srv.secrets) serviceslist));
        in ''
            # Generates the SSL secrets for ${recipient}
            ${lib.concatMapStringsSep "\n" gen.gen_openssl pwsecrets}
            # Encrypt
            ${lib.concatMapStringsSep "\n" (gen.encrypt recipient) (lib.concatMap (sec: sec.names) pwsecrets) }
        '';


    # list of the hosts running garage (the S3 service)
    s3hosts = registry.services."garage".hosts.vms
           ++ (lib.map (vmname: get-ct-id vmname "garage") 
                    registry.services."garage".hosts.containers);
    processS3Secrets = recipient: serviceslist:
        let s3access = lib.concatMap (srv: srv.s3Accesses) serviceslist;
        in ''
            # S3 Accesses for ${recipient}
            ${lib.concatMapStringsSep "\n" 
                (access: gen.provider-openssl "s3-${access.bucket}_id" 64 "hex") s3access}
            ${lib.concatMapStringsSep "\n" 
                (access: gen.provider-openssl "s3-${access.bucket}.key" 64 "hex") s3access}
            ${lib.concatMapStringsSep "\n"
                (gen.encrypt recipient) 
                (lib.map (access: "s3-${access.bucket}.key") s3access)}
            ${lib.concatMapStringsSep "\n"
                (filename:
                    lib.concatMapStringsSep "\n"
                        (recipient: gen.encrypt recipient filename) 
                        s3hosts)
                (lib.map (access: "s3-${access.bucket}.key") s3access)}


        '';

    # list of the hosts running postgres (the DB service)
    dbhosts = registry.services."postgres".hosts.vms
           ++ (lib.map (vmname: get-ct-id vmname "postgres") 
                    registry.services."postgres".hosts.containers);

    processDBSecrets = recipient: serviceslist:
        let dbaccess = lib.concatMap (srv: srv.dbAccesses) serviceslist;
        in ''
            #DB Accesses for ${recipient}
            ${lib.concatMapStringsSep "\n" 
                (access: gen.provider-openssl "db-${access.role}-${access.table}.key" 64 "base64") dbaccess}
            ${lib.concatMapStringsSep "\n"
                (gen.encrypt recipient) 
                (lib.map (access: "db-${access.role}-${access.table}.key") dbaccess)}
            ${lib.concatMapStringsSep "\n"
                (filename:
                    lib.concatMapStringsSep "\n"
                        (recipient: gen.encrypt recipient filename) 
                        dbhosts)
                (lib.map (access: "db-${access.role}-${access.table}.key") dbaccess)}


            


        '';

    gen_step_ca = ''
        PWD=$(pwd)
        export STEPPATH="$PWD/${infra.secretsPath}/plain/CA";
        CA_NAME="ca.${infra.domain}"

        if [[ ! -d $STEPPATH ]]; then
            install -d -m 711 "$STEPPATH"
            umask 077
            ${lib.getExe pkgs.openssl} rand -base64 48 > "$STEPPATH"/ca-password
            ${lib.getExe pkgs.step-cli} ca init \
                --dns $CA_NAME \
                --name $CA_NAME \
                --password-file "$STEPPATH"/ca-password \
                --deployment-type standalone \
                --address :443 \
                --provisioner=ca

            # Patching STEPPATH
            sed -i "s+$STEPPATH/secrets+/run/secrets+" "$STEPPATH"/config/ca.json 
            sed -i "s+$STEPPATH/certs+/run/secrets+" "$STEPPATH"/config/ca.json 
            sed -i "s+$STEPPATH+/var/lib/step-ca+" "$STEPPATH"/config/ca.json 

            ${lib.getExe pkgs.step-cli} certificate fingerprint "$STEPPATH/certs/root_ca.crt" | tr -d '\n' > "$STEPPATH/fingerprint" # step adds a \n at the end of the line
        fi

    '';

    processSSLCertificates = recipient: serviceslist:
        let sslcerts = utils.mergeAll (lib.map (srv: srv.sslCertificates) serviceslist);
        in ''
            ${lib.concatStringsSep "\n"
                (lib.mapAttrsToList
                    (crtname: certificate:
                    ''
                        ${gen.gen_ssl_certificate crtname}
                        ${gen.encrypt recipient "${crtname}.crt"}
                        ${gen.encrypt recipient "${crtname}.key"}

                    ''
                    )
                    sslcerts)}
        '';

    processEndpoints = recipient: serviceslist:
        let endpoints = lib.filter 
                            (endpoint: endpoint.is_http)
                            (lib.concatMap (srv: srv.endpoints) serviceslist);
        in ''
            ${lib.concatStringsSep "\n"
                (lib.map
                    (endpoint:
                    ''
                        ${gen.gen_ssl_certificate endpoint.host}
                        ${gen.encrypt recipient "${endpoint.host}.crt"}
                        ${gen.encrypt recipient "${endpoint.host}.key"}

                    ''
                    )
                    endpoints)}
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
                pkgs.sops
                pkgs.step-cli
            ];
            # For each kind of secret, we generate for the services running natively AND running within a container
            text = ''
                    set -x
                    ${gen_all_ages}

                    ${gen_step_ca}

                    #Password Secrets
                    ${lib.concatStringsSep "\n" 
                        (lib.mapAttrsToList
                            (vmname: serviceslist:
                                processPasswordSecrets vmname serviceslist)
                            allServices)}
                    ${lib.concatStringsSep "\n" 
                        (lib.mapAttrsToList
                            (ctname: serviceslist:
                                processPasswordSecrets ctname serviceslist)
                            allContainers)}

                    #S3Secrets
                    ${lib.concatStringsSep "\n" 
                        (lib.mapAttrsToList
                            (vmname: serviceslist:
                                processS3Secrets vmname serviceslist)
                            allServices)}
                    ${lib.concatStringsSep "\n" 
                        (lib.mapAttrsToList
                            (vmname: serviceslist:
                                processS3Secrets vmname serviceslist)
                            allContainers)}

                    #DBSecrets
                    ${lib.concatStringsSep "\n" 
                        (lib.mapAttrsToList
                            (vmname: serviceslist:
                                processDBSecrets vmname serviceslist)
                            allServices)}
                    ${lib.concatStringsSep "\n" 
                        (lib.mapAttrsToList
                            (vmname: serviceslist:
                                processDBSecrets vmname serviceslist)
                            allContainers)}

                    #Certificates
                    ${lib.concatStringsSep "\n" 
                        (lib.mapAttrsToList
                            (vmname: serviceslist:
                                processSSLCertificates vmname serviceslist)
                            allServices)}
                    ${lib.concatStringsSep "\n" 
                        (lib.mapAttrsToList
                            (vmname: serviceslist:
                                processSSLCertificates vmname serviceslist)
                            allContainers)}
                    #Endpoints
                    ${lib.concatStringsSep "\n" 
                        (lib.mapAttrsToList
                            (vmname: serviceslist:
                                processEndpoints vmname serviceslist)
                            allServices)}
                    ${lib.concatStringsSep "\n" 
                        (lib.mapAttrsToList
                            (vmname: serviceslist:
                                processEndpoints vmname serviceslist)
                            allContainersInVM)}






            '';
    };
}
