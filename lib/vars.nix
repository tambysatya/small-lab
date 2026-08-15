/* Standard definitions of names, paths... */

{lib, infra, inputs,...}:

let

    #paths 
    path = infra.secretsPath;
    age = lib.escapeShellArg "${lib.escapeShellArg infra.secretsPath}/age";
    plain = "${lib.escapeShellArg infra.secretsPath}/plain";
    git = "${lib.escapeShellArg infra.secretsPath}/git"; #everything that can be versionned
    enc = "${git}/enc";
    ssl_root =  "/var/lib/ssl";
    ssl_basedir = name: "${ssl_root}/${name}";
    ssl_crt_path = name: "${ssl_basedir name}/${name}/${name}.crt";
    ssl_key_path = name: "${ssl_basedir name}/${name}/${name}.key";

    #naming conventions
    container_id = vmname: service: "ct-${vmname}-${service}"; #returns the containers ID
    s3_key_id = access@{bucket,...}: "s3-${bucket}_id";
    s3_key = access@{bucket,...}: "s3-${bucket}.key";
    db_key = access@{role, table, ...}: "db-${role}-${table}.key";

in {
    inherit path age plain git enc;
    inherit container_id;
    inherit ssl_root ssl_basedir ssl_crt_path ssl_key_path;
    inherit s3_key s3_key_id db_key;
}
