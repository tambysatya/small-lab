/* Standard definitions of names, paths... */

{lib, inputs,...}:

let

    #paths 
    ssl_root = "/var/lib/ssl";
    ssl_basedir = name: "${ssl_root}/${name}";
    ssl_crt_path = name: "${ssl_basedir name}/${name}.crt";
    ssl_key_path = name: "${ssl_basedir name}/${name}.key";

    #naming conventions
    container_id = vmname: service: "${vmname}-${service}"; #returns the containers ID
    s3_key_id = access@{bucket,...}: "s3-${bucket}.id";
    s3_key = access@{bucket,...}: "s3-${bucket}.key";
    db_key = access@{database, ...}: "db-${database}.key";

in {
    inherit container_id;
    inherit ssl_root ssl_basedir ssl_crt_path ssl_key_path;
    inherit s3_key s3_key_id db_key;
}
