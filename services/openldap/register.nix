{lib, inputs,  pkgs, config, ...}:

let 

    infra = config.infra;
    reg = import "${inputs.self.outPath}/lib/registry/register.nix" {inherit inputs lib infra;};
in {
    config.registry = 
                      (lib.mkMerge [
                            (reg.registerCertificate "openldap" "openldap" ["openldap.service"] "openldap.${infra.domain}")
                            (reg.registerEndpoints "openldap" [
                                        {host = "openldap.${infra.domain}"; port=389; is_http=false;} #ldap
                                        {host = "openldap.${infra.domain}"; port=636; is_http=false;} #ldaps
                                ])
                            (reg.registerUser "openldap" "openldap" 10004)
                    ]);
}

