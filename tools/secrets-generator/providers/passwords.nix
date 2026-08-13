/* Basic passwords generated with openssl rand */

{inputs, lib, infra, registry, pkgs, ...}:
let
    age = import ../age.nix {inherit inputs lib infra registry pkgs;};
    vars = import ../vars.nix {inherit inputs lib infra registry pkgs;};
    gen_password = name: size: type:
        ''
            mkdir -p ${vars.plain}
            if [[ ! -f  "${vars.plain}/${lib.escapeShellArg name}" ]]; then
                umask 077
                ${lib.getExe pkgs.openssl} rand -${type} ${lib.toString size} > ${vars.plain}/${lib.escapeShellArg name}
            fi
        '';
    provider_openssl = secret: 
            lib.concatMapStringsSep "\n" 
                (name:
                    gen_password name secret.kind.providerArgs.size secret.kind.providerArgs.type)
                secret.names;

    processPasswordSecrets = recipient: serviceslist:
        let pwsecrets = 
                (lib.filter (sec: sec.kind.provider == "openssl") 
                    (lib.concatMap (srv: builtins.attrValues srv.secrets) serviceslist));
        in ''
            # Generates the SSL secrets for ${recipient}
            ${lib.concatMapStringsSep "\n" provider_openssl pwsecrets}
            # Encrypt
            ${lib.concatMapStringsSep "\n" (age.encrypt recipient) (lib.concatMap (sec: sec.names) pwsecrets) }
        '';
in {
    inherit gen_password processPasswordSecrets;
}


