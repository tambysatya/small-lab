/* Accounts generation:
   Everything that amounts to share a secret between multiple services.
*/

{inputs, lib, infra, registry, pkgs, ...}:

let
    utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};
    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit inputs lib infra registry pkgs;};
    age = import ../age.nix {inherit inputs lib infra registry pkgs;};
    pw = import ./passwords.nix {inherit inputs lib infra registry pkgs;};


    bootstrap_ldap = # generates and hash a root password
        if ! builtins.hasAttr "openldap" registry.services
        then '' ''
        else ''
                ${pw.gen_password "ldap-adminpass" 64 "hex"}
                cat ${vars.plain}/ldap-adminpass \
                    | ${pkgs.openldap}/bin/slappasswd -s -- -h "{SSHA}" \
                    > ${vars.git}/ldap-adminpass.ssha
             '';


    # list of the hosts running garage (the S3 service)
    s3hosts = registry.services."garage".hosts.vms
              ++ (lib.map (vmname: vars.container_id vmname "garage") 
                    registry.services."garage".hosts.containers);
    processS3Secrets = recipient: serviceslist:
        let s3access = lib.concatMap (srv: srv.s3Accesses) serviceslist;
        in ''
            # S3 Accesses for ${recipient}
            ${lib.concatMapStringsSep "\n" 
                (access:
                    ''
                        ${pw.gen_password (vars.s3_key_id access) 64 "hex"}
                        cp ${vars.plain}/${vars.s3_key_id access} ${vars.git}/
                    '') s3access}
            ${lib.concatMapStringsSep "\n" 
                (access: pw.gen_password (vars.s3_key access) 64 "hex") s3access}
            ${lib.concatMapStringsSep "\n"
                (age.encrypt recipient) 
                (lib.map vars.s3_key s3access)}
            ${lib.concatMapStringsSep "\n"
                (filename:
                    lib.concatMapStringsSep "\n"
                        (recipient: age.encrypt recipient filename) 
                        s3hosts)
                (lib.map vars.s3_key s3access)}


        '';

    # list of the hosts running postgres (the DB service)
    dbhosts = registry.services."postgres".hosts.vms
              ++ (lib.map (vmname: vars.container_id vmname "postgres") 
                    registry.services."postgres".hosts.containers);

    processDBSecrets = recipient: serviceslist:
        let dbaccess = lib.concatMap (srv: srv.dbAccesses) serviceslist;
        in ''
            #DB Accesses for ${recipient}
            ${lib.concatMapStringsSep "\n" 
                (access: pw.gen_password (vars.db_key access) 64 "base64") dbaccess}
            ${lib.concatMapStringsSep "\n"
                (age.encrypt recipient) 
                (lib.map vars.db_key dbaccess)}
            ${lib.concatMapStringsSep "\n"
                (filename:
                    lib.concatMapStringsSep "\n"
                        (recipient: age.encrypt recipient filename) 
                        dbhosts)
                (lib.map vars.db_key dbaccess)}
        '';

in
{
    inherit bootstrap_ldap processS3Secrets processDBSecrets;
}
