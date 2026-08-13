
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
in {
    inherit gen_age encrypt provider-openssl gen_openssl gen_ssl_certificate gen_age_token; 
}

