{lib,...}:
  let inherit (lib) types;
in
types // rec {
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
            type = types.listOf (types.submodule {
                options = {
                    host = lib.mkOption {
                        description = "Virtualhost that will be created";
                        example = "nextcloud.domain";
                        type = types.str;
                    };
                    port = lib.mkOption {
                        description = "Port on which nginx can reach the service. If the service runs within a container the firewall must be oppened";
                        type = types.port;
                    };
                    is_http = lib.mkOption {
                        description = "If set to false, the redirection will be done using port forwarding (through nat). Otherwise, the forwarding will be done using nginx"; #TODO
                        type = types.bool;
                        default = true;
                    };
                };
           });
        };
        secrets = lib.mkOption{ 
            internal = true;
            description = "List of required by the service";
            default = {};
            type = types.attrsOf (types.submodule {
                options = {
                  path = lib.mkOption {
                    description = "Mount point";
                    type = types.str;
                    example = "/run/secrets/nextcloud.key";
                  };
                  owner = lib.mkOption {
                    description = "Secret owner";
                    type = types.str;
                    default = "root";
                  };
                  restartUnits = lib.mkOption {
                    type = types.listOf types.str;
                    default = [];
                  };
                  mode = lib.mkOption {
                    description = "permissions";
                    type = types.str;
                    default = "044";
                  };
                };
            });
        };
     };
  };

}
