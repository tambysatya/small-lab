{lib,...}:
let libtypes = lib.types;
    customtypes = import ../../../../lib/types.nix {inherit lib;};
    types = libtypes // customtypes;
    
in
{
    serviceConfig = lib.types.submodule {
      options = {
        settings = lib.mkOption {
            description = "Service configuration (same type as the service configuration)";
            type = types.attrs;
        };
        endpoints = lib.mkOption{ 
            internal = true;
            description = "List of reverse proxy that will be created";
            default = [];
            type = types.listOf types.endpoint;
        };
        secrets = lib.mkOption{ 
            internal = true;
            description = "List of required by the service";
            default = {};
            type = types.attrsOf types.secret;
        };
        sslCertificates = lib.mkOption{
            internal = true;
            description = "List of TLS certificates handled by the service";
            default = {};
            type = types.attrsOf types.sslCertificate;
        };
        dbAccesses = lib.mkOption {
            internal = true;
            description  = "List of user/tables to be created on the database. The tables will be accessible through TLS only. Note that the password is set at every-rebuild so you can change it without losing access to the datas.";
            default = [];
            type = types.listOf types.dbAccess;
        };
        S3Accesses = lib.mkOption {
            internal = true;
            description  = "List of bucket/key to be created on the s3 server.";
            default = [];
            type = types.listOf types.S3Access;
        };
     };
  };

}
