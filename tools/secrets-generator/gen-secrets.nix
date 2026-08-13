
/* Basic functions to generates simple secrets */

{inputs, lib, infra, pkgs, ...}:

let
    path = infra.secretsPath;
    age = lib.escapeShellArg "${infra.secretsPath}/age";
    plain = lib.escapeShellArg "${infra.secretsPath}/plain";
    enc = lib.escapeShellArg "${infra.secretsPath}/encrypted";

    generate_age = name:  #Generate an AGE keypair for a vm or a container
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
    generate_plain_hex = name: size:
        ''
            mkdir -p ${plain}
            if [[ ! -f  "${plain}/${lib.escapeShellArg name}" ]]; then
                umask 077
                ${lib.getExe pkgs.openssl} rand -hex ${size} > ${plain}/${lib.escapeShellArg name}
            fi
        '';

    encrypt = recipient: secretname: 
        ''
           mkdir -p ${enc} 
           SRC=${plain}/${lib.escapeShellArg secretname}
           KEY=${age}/${lib.escapeShellArg recipient}.pub
           TARGET=${enc}/${lib.escapeShellArg "${recipient}-${secretname}.enc"}
           ${lib.getExe pkgs.sops} --input-type binary --output-type binary \
                encrypt --age $KEY $SRC \
                > $TARGET
        '';

in {
    inherit generate_plain_hex generate_age encrypt;
}

