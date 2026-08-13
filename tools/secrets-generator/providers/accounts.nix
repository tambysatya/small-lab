/* Accounts generation:
   Everything that amounts to share a secret between multiple services.
*/

{inputs, lib, infra, registry, pkgs, ...}:

let
    age = import ../age.nix {inherit inputs lib infra registry pkgs;};
    vars = import ../vars.nix {inherit inputs lib infra registry pkgs;};
    pw = import ./passwords.nix {inherit inputs lib infra registry pkgs;};


    # list of the hosts running garage (the S3 service)
    s3hosts = registry.services."garage".hosts.vms
           ++ (lib.map (vmname: vars.get-ct-id vmname "garage") 
                    registry.services."garage".hosts.containers);
    processS3Secrets = recipient: serviceslist:
        let s3access = lib.concatMap (srv: srv.s3Accesses) serviceslist;
        in ''
            # S3 Accesses for ${recipient}
            ${lib.concatMapStringsSep "\n" 
                (access:
                    ''
                        ${pw.gen_password "s3-${access.bucket}_id" 64 "hex"}
                        cp ${vars.plain}/s3-${access.bucket}_id ${vars.git}/
                    '') s3access}
            ${lib.concatMapStringsSep "\n" 
                (access: pw.gen_password "s3-${access.bucket}.key" 64 "hex") s3access}
            ${lib.concatMapStringsSep "\n"
                (age.encrypt recipient) 
                (lib.map (access: "s3-${access.bucket}.key") s3access)}
            ${lib.concatMapStringsSep "\n"
                (filename:
                    lib.concatMapStringsSep "\n"
                        (recipient: age.encrypt recipient filename) 
                        s3hosts)
                (lib.map (access: "s3-${access.bucket}.key") s3access)}


        '';

    # list of the hosts running postgres (the DB service)
    dbhosts = registry.services."postgres".hosts.vms
           ++ (lib.map (vmname: vars.get-ct-id vmname "postgres") 
                    registry.services."postgres".hosts.containers);

    processDBSecrets = recipient: serviceslist:
        let dbaccess = lib.concatMap (srv: srv.dbAccesses) serviceslist;
        in ''
            #DB Accesses for ${recipient}
            ${lib.concatMapStringsSep "\n" 
                (access: pw.gen_password "db-${access.role}-${access.table}.key" 64 "base64") dbaccess}
            ${lib.concatMapStringsSep "\n"
                (age.encrypt recipient) 
                (lib.map (access: "db-${access.role}-${access.table}.key") dbaccess)}
            ${lib.concatMapStringsSep "\n"
                (filename:
                    lib.concatMapStringsSep "\n"
                        (recipient: age.encrypt recipient filename) 
                        dbhosts)
                (lib.map (access: "db-${access.role}-${access.table}.key") dbaccess)}
        '';

in
{
    inherit processS3Secrets processDBSecrets;
}
