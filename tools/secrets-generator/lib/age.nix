{lib, inputs, pkgs,...}:
let
    generateAge = 
        identity:
        let 
            priv = ".secrets/keys/${identity}.key";
            pub = ".secrets/keys/pub-${identity}.key";
        in ''
            umask 077
            if [[ ! -f ${priv} ]]; then
                ${pkgs.age}/bin/age-keygen -o ${priv}
                ${pkgs.age}/bin/age-keygen -y ${priv}\
                    > ${pub}
                cp ${priv} .secrets/plain
            fi
        '';
    encrypt = filename: identity: 
        let filepath = ".secrets/plain/${filename}";
            pubkey = ".secrets/keys/pub-${identity}.key";
            target = ".secrets/git/enc/${identity}-${filename}.enc";
        in 
        ''
           KEY=$(cat ${pubkey})
           ${lib.getExe pkgs.sops} \
                --input-type binary \
                --output-type binary \
                encrypt --age "$KEY" ${filepath} \
                > ${target}
        '';



in
{
    inherit encrypt generateAge;
}
