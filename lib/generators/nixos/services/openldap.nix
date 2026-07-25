
{lib, inputs, ...}:


let 
  pkgs = inputs.nixpkgs.pkgs;
  certlib = import ./step-renew.nix {inherit lib inputs;};
  domainToLdapSuffix = domain:
    let parts = lib.reverseList (lib.splitString "." domain);
    in lib.concatString "," (lib.map (x: "dc=${x}") parts);
in {

  generator = 
    infra: vmName:
      let settings = infra.services.openldap.setings or {};
          suffix = domainToLdapSuffix infra.domain;
      in 
      lib.mkMerge ([{
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
              olcTLSCertificateFile = "/var/lib/openldap/openldap.crt";
              olcTLSCertificateKeyFile = "/var/lib/openldap/openldap.key";

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
                  olcDbDirectory = "/var/lib/openldap/data"; 
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

      }
      (certlib.registerCertificate infra vmName "openldap" "openldap")]);

}
