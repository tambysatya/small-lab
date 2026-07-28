
{lib, inputs, infra, vmname, vmconf, pkgs, config, ...}:

let
    domainToLdapSuffix = domain:
        let parts = lib.reverseList (lib.splitString "." domain);
        in lib.concatString "," (lib.map (x: "dc=${x}") parts);
    suffix = domainToLdapSuffix infra.domain;

in {
    config = lib.mkIf (builtins.elem "openldap" vmconf.services)
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
                    olcTLSCertificateFile = config.services.step-renew.certs.openldap.cert;
                    olcTLSCertificateKeyFile = config.services.step-renew.certs.openldap.key;
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
                            olcRootPW = builtins.readFile "${inputs.self.outPath}/secrets/plain/ldap-adminpass.ssha";
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

