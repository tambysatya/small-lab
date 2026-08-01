
{lib, inputs, infra, vmname, vmconf, pkgs, config, ...}:

let
    infralib = import ../infra/lib.nix {inherit lib vmconf vmname;};
    domainToLdapSuffix = domain:
        let parts = lib.reverseList (lib.splitString "." domain);
        in lib.concatStringsSep "," (lib.map (x: "dc=${x}") parts);
    suffix = domainToLdapSuffix infra.domain;

in {
    config = lib.mkIf (infralib.hostsService "openldap")
    {
        services.openldap = {
            enable = true;

            urlList = [
                "ldap:///"
                    "ldaps:///"
                    "ldapi:///"
            ];

            settings = {
                attrs = {
                    olcTLSCACertificateFile = "/etc/root_ca.crt";
                    olcTLSCertificateFile = config.services.step-renew.certs."openldap.${infra.domain}".cert;
                    olcTLSCertificateKeyFile = config.services.step-renew.certs."openldap.${infra.domain}".key;
# facultatif
                    olcTLSProtocolMin = "3.1";      # TLS 1.2+
                        olcTLSVerifyClient = "never";
                };

                children = {
                    "cn=schema".includes = [
                        "${pkgs.openldap}/etc/schema/core.ldif"
                            "${pkgs.openldap}/etc/schema/cosine.ldif"
                            "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
                            "${pkgs.openldap}/etc/schema/nis.ldif"
                    ];
                    "olcDatabase={1}mdb" = {
                        attrs = {
                            objectClass = [
                                "olcDatabaseConfig"
                                    "olcMdbConfig"
                            ];
                            olcSuffix = suffix;
                            olcRootDN = "cn=admin,${suffix}";
                            olcRootPW = builtins.readFile "${infra.secrets-path}/plain/ldap-adminpass.ssha";
                            olcDbDirectory = "/var/lib/openldap/data";  #TODO persistent
                                olcDbIndex = [
                                "objectClass eq"
                                    "cn pres,eq"
                                    "uid pres,eq"
                                    "sn pres,eq,subany"
                                ];
                        };
                    };
                };
            };

        };

    };
}

