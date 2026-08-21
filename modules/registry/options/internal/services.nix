{lib,...}:
let libtypes = lib.types;
    customtypes = import ../register.nix {inherit lib;};
    types = libtypes // customtypes;
    
in
{
    serviceConfig = lib.types.submodule {
      options = {
        endpoints = lib.mkOption{ 
            description = "List of reverse proxy that will be created";
            type = types.listOf types.endpoint;
            default = [];
        };
        secrets = lib.mkOption{ 
            description = "List of required by the service";
            type = types.attrsOf types.secret;
            default = {};
        };
        sslCertificates = lib.mkOption{
            internal = true;
            description = "List of TLS certificates handled by the service";
            type = types.attrsOf types.sslCertificate;
            default = {};
        };
        dbAccesses = lib.mkOption {
            internal = true;
            description  = "List of user/tables to be created on the database. The tables will be accessible through TLS only. Note that the password is set at every-rebuild so you can change it without losing access to the datas.";
            type = types.listOf types.dbAccess;
            default = [];
        };
        s3Accesses = lib.mkOption {
            internal = true;
            description  = "List of bucket/key to be created on the s3 server.";
            type = types.listOf types.s3Access;
            default = [];
        };
        volumes = lib.mkOption {
            internal = true;
            description = "List of directories containing persistent data.";
            type = types.listOf types.volume;
            default = [];
        };
        users = lib.mkOption {
            internal = true;
            description = "UserIDs of the Service Users";
            type = types.attrsOf types.userID;
            default = {};

        };
        hosts = lib.mkOption {
            internal = true;
            description = "Which machines/containers run this service";
            type = types.submodule {
                options = {
                    vms = lib.mkOption {
                        description = "List of the virtual machines running the service natively";
                        type = types.listOf types.str;
                        default = [];
                    };
                    containers = lib.mkOption {
                        description = "List of the virtual machines on which the service runs within a container";
                        type = types.listOf types.str;
                        default = [];
                    };
                };
            };
        };
     };
  };

}
