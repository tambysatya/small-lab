/* Everything related to TLS/SSH certificates managed with step-CA */


{inputs, lib, infra, registry, pkgs, ...}:

let

    utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};
    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit inputs lib infra pkgs registry;};
    age = import ../age.nix {inherit inputs lib infra pkgs registry;};


    # identities hosting step-ca
    stepcahosts = registry.services."step-ca".hosts.vms
                ++ (lib.map (vmname: vars.container_id vmname "step-ca") 
                    registry.services."step-ca".hosts.containers);
    bootstrap_step_ca = ''
        PWD=$(pwd)
        mkdir -p ${vars.plain}
        export STEPPATH="$PWD/${vars.plain}/CA";
        CA_NAME="ca.${infra.domain}"

        if [[ ! -d $STEPPATH ]]; then
            install -d -m 711 "$STEPPATH"
            umask 077
            ${lib.getExe pkgs.openssl} rand -base64 48 \
                | tr -d '\n' \
                > "$STEPPATH"/ca-password.key
            ${lib.getExe pkgs.step-cli} ca init \
                --dns $CA_NAME \
                --name $CA_NAME \
                --password-file "$STEPPATH"/ca-password.key \
                --deployment-type standalone \
                --address :443 \
                --provisioner=ca

            # Patching STEPPATH
            sed -i "s+$STEPPATH/secrets+/run/secrets+" "$STEPPATH"/config/ca.json 
            sed -i "s+$STEPPATH/certs+/etc+" "$STEPPATH"/config/ca.json 
            sed -i "s+$STEPPATH+/var/lib/step-ca+" "$STEPPATH"/config/ca.json 

            ${lib.getExe pkgs.step-cli} certificate fingerprint "$STEPPATH/certs/root_ca.crt" \
                | tr -d '\n' \
                > "$STEPPATH/fingerprint" # step adds a \n at the end of the line
        fi

        cp "$STEPPATH/ca-password.key" ${vars.plain}/
        cp "$STEPPATH/secrets/intermediate_ca_key" ${vars.plain}/

        ${lib.concatStringsSep "\n" 
            (lib.map (recipient: age.encrypt recipient  "ca-password.key") stepcahosts)}
        ${lib.concatStringsSep "\n" 
            (lib.map (recipient: age.encrypt recipient  "intermediate_ca_key") stepcahosts)}
        
        
        mkdir -p ${vars.git}
        cp "$STEPPATH/fingerprint" ${vars.git}
        cp "$STEPPATH/config/ca.json" ${vars.git}
        cp "$STEPPATH/certs/root_ca.crt" ${vars.git}
        cp "$STEPPATH/certs/intermediate_ca.crt" ${vars.git}

    '';


    gen_ssl_certificate = crtname:
            ''
                PWD=$(pwd)
                export STEPPATH="$PWD/${infra.secretsPath}/plain/CA";

                TARGET_PATH="${infra.secretsPath}/plain"
                if [[ -f "$TARGET_PATH/${crtname}.key" ]]; then
                    rm "$TARGET_PATH/${crtname}.key"
                fi
                if [[ -f "$TARGET_PATH/${crtname}.crt" ]]; then
                    rm "$TARGET_PATH/${crtname}.crt"
                fi
                ${lib.getExe pkgs.step-cli} certificate create \
                    ${crtname} "$TARGET_PATH/${crtname}.crt" "$TARGET_PATH/${crtname}.key" \
                    --san ${crtname} \
                    --ca "$STEPPATH/certs/intermediate_ca.crt" --ca-key "$STEPPATH/secrets/intermediate_ca_key" \
                    --ca-password-file "$STEPPATH/ca-password.key" \
                    --no-password --insecure
            '';




    processSSLCertificates = recipient: serviceslist:
        let sslcerts = utils.mergeAll (lib.map (srv: srv.sslCertificates) serviceslist);
        in ''
            ${lib.concatStringsSep "\n"
                (lib.mapAttrsToList
                    (crtname: certificate:
                    ''
                        ${gen_ssl_certificate crtname}
                        ${age.encrypt recipient "${crtname}.crt"}
                        ${age.encrypt recipient "${crtname}.key"}

                    ''
                    )
                    sslcerts)}
        '';

    processHTTPEndpoints = recipient: serviceslist:
        let endpoints = lib.filter 
                            (endpoint: endpoint.is_http)
                            (lib.concatMap (srv: srv.endpoints) serviceslist);
        in ''
            ${lib.concatStringsSep "\n"
                (lib.map
                    (endpoint:
                    ''
                        ${gen_ssl_certificate endpoint.host}
                        ${age.encrypt recipient "${endpoint.host}.crt"}
                        ${age.encrypt recipient "${endpoint.host}.key"}

                    ''
                    )
                    endpoints)}
        '';
   


in 

{
    inherit bootstrap_step_ca processSSLCertificates processHTTPEndpoints gen_ssl_certificate;
}
