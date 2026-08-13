{lib, inputs, infra, vmname, vmconf, pkgs, config, ...}:

let 
    reg = import ../registry/lib/register.nix {inherit lib inputs infra vmname vmconf;};
    infralib = import ../infra/lib.nix {inherit lib vmconf vmname;};

in {
    config = 
                      (lib.mkMerge [
                            (reg.registerCertificate "openldap" "openldap" ["openldap.service"] "openldap.${infra.domain}")
                            (reg.registerEndpoints "openldap" [
                                        {host = "openldap.${infra.domain}"; port=389; is_http=false;} #ldap
                                        {host = "openldap.${infra.domain}"; port=636; is_http=false;} #ldaps
                                ])]);
}

