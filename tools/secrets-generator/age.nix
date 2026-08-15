/* Basic age primitives */
{inputs, lib, pkgs, infra, registry, ...}:

let
    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit inputs lib pkgs infra registry;};
    gen_age = name:  #Generate an AGE keypair for a vm or a container
        ''
            TARGET=${vars.age}/${lib.escapeShellArg name}
            umask 077
            mkdir -p ${vars.age}
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
            mkdir -p ${vars.path}/provisionner/tokens
            cp "${vars.age}/${lib.escapeShellArg name}.key" "${vars.path}/provisionner/tokens/$TOKEN"
            echo "$TOKEN" > /tmp/${lib.escapeShellArg name}.token
            
        '';
    encrypt = recipient: secretname: 
        ''
           mkdir -p ${vars.enc} 
           SRC=${vars.plain}/${lib.escapeShellArg secretname}
           KEY=$(cat ${vars.age}/${lib.escapeShellArg recipient}.pub)
           TARGET=${vars.enc}/${lib.escapeShellArg "${recipient}-${secretname}.enc"}
           ${lib.getExe pkgs.sops} --input-type binary --output-type binary \
                encrypt --age "$KEY" "$SRC" \
                > "$TARGET"
        '';
    encrypt_key = recipient: keyname: 
        ''
           mkdir -p ${vars.enc} 
           SRC=${vars.age}/${lib.escapeShellArg keyname}
           KEY=$(cat ${vars.age}/${lib.escapeShellArg recipient}.pub)
           TARGET=${vars.enc}/${lib.escapeShellArg "${recipient}-${keyname}.enc"}
           ${lib.getExe pkgs.sops} --input-type binary --output-type binary \
                encrypt --age "$KEY" "$SRC" \
                > "$TARGET"
        '';



in {
    inherit gen_age encrypt encrypt_key gen_age_token; 
}
