{lib,...}:
let inherit (lib) types;
    customtypes = import ../../lib/types.nix {inherit lib;};
    
in
types // customtypes // rec {
    serviceConfig = lib.types.submodule {
      options = {
        settings = lib.mkOption {
            description = "Service configuration (same type as the service configuration)";
            type = types.attrs;
        };
        postgresTables = lib.mkOption {
            description  = "List of tuples user/tables to be created on the database. The tables will be accessible through TLS only. Note that the password is set at every-rebuild so you can change it without losing access to the datas.";
            type = types.listOf (
                      types.submodule {
                        user = lib.mkOption {
                            type = types.str;
                            description = "Login acconunt";
                            example = "nextcloud";
                        };
                        table = lib.mkOption {
                            type = types.str;
                            description = "Table to be created";
                            example = "nextcloud";
                        };
                        passFile = lib.mkOption {
                            type = types.str;
                            description = "File containing the password (use double quotes to avoid it being stored publically)";
                            example = "/run/secrets/nextcloud-db.key";
                        };
                    });
        };
        endpoints = lib.mkOption{ 
            internal = true;
            description = "List of reverse proxy that will be created";
            default = [];
            type = types.listOf customtypes.endpoint;
        };
        secrets = lib.mkOption{ 
            internal = true;
            description = "List of required by the service";
            default = {};
            type = types.attrsOf customtypes.secret;
        };
        sslCertificates = lib.mkOption{
            internal = true;
            description = "List of TLS certificates handled by the service";
            default = {};
            type = types.attrsOf customtypes.sslCertificate;

        };
     };
  };

}
