
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
            mkdir -p ${age}
            if [[ ! -f $TARGET.key ]]; then
                umask 077
                ${pkgs.age}/bin/age-keygen -o $TARGET.key
                ${pkgs.age}/bin/age-keygen -y $TARGET.key \
                    > $TARGET.pub
            fi
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

    gen_openssl= secret: 
            lib.concatMapStringsSep "\n" (name: provider-openssl name secret.kind.providerArgs.size secret.kind.providerArgs.type) secret.names;

in {
    inherit gen_age encrypt gen_openssl; 
}

