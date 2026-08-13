
/* Basic functions to generates simple secrets */

{inputs, lib, infra, pkgs, ...}:

let
    path = infra.secretsPath;
    age = lib.escapeShellArg "${infra.secretsPath}/age";
    plain = lib.escapeShellArg "${infra.secretsPath}/plain";
    enc = lib.escapeShellArg "${infra.secretsPath}/encrypted";

    gen_age = name:  #Generate an AGE keypair for a vm or a container
        ''
            TARGET=${age}/${lib.escapeShellArg name}
            umask 077
            mkdir -p ${age}
            if [[ ! -f $TARGET.key ]]; then
                ${pkgs.age}/bin/age-keygen -o $TARGET.key
                ${pkgs.age}/bin/age-keygen -y $TARGET.key \
                    > $TARGET.pub
            fi
         '';
    gen_age_token = name:
        ''
            TOKEN_NUMBER=$(${lib.getExe pkgs.openssl} rand -hex 32)
            TOKEN="${name}$TOKEN_NUMBER"
            mkdir -p ${path}/tokens
            cp "${age}/${lib.escapeShellArg name}.key" "${path}/tokens/$TOKEN"
            echo "$TOKEN" > /tmp/${lib.escapeShellArg name}.token
            
        '';
    provider-openssl = name: size: type:
        ''
            mkdir -p ${plain}
            if [[ ! -f  "${plain}/${lib.escapeShellArg name}" ]]; then
                umask 077
                ${lib.getExe pkgs.openssl} rand -${type} ${lib.toString size} > ${plain}/${lib.escapeShellArg name}
            fi
        '';

    encrypt = recipient: secretname: 
        ''
           mkdir -p ${enc} 
           SRC=${plain}/${lib.escapeShellArg secretname}
           KEY=$(cat ${age}/${lib.escapeShellArg recipient}.pub)
           TARGET=${enc}/${lib.escapeShellArg "${recipient}-${secretname}.enc"}
           ${lib.getExe pkgs.sops} --input-type binary --output-type binary \
                encrypt --age "$KEY" "$SRC" \
                > "$TARGET"
        '';

    gen_openssl = secret: 
            lib.concatMapStringsSep "\n" (name: provider-openssl name secret.kind.providerArgs.size secret.kind.providerArgs.type) secret.names;
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
                    --ca-password-file "$STEPPATH/ca-password" \
                    --no-password --insecure
            '';

in {
    inherit gen_age encrypt provider-openssl gen_openssl gen_ssl_certificate gen_age_token; 
}

