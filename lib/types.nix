/* Basic type definition */
{lib,...}:
let inherit (lib) types;
in
{

    sslCertificate = types.submodule {
        options = {
            cert = lib.mkOption {type=types.str;};
            key = lib.mkOption {type = types.str;};
            reload = lib.mkOption {type = types.listOf types.str;};
        };
    };
    secret = types.submodule {
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
              reload = lib.mkOption {
                type = types.listOf types.str;
                default = [];
              };
              mode = lib.mkOption {
                description = "permissions";
                type = types.str;
                default = "044";
              };
            };
        };
        endpoint = types.submodule {
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
        };
        dbAccess = types.submodule {
            options = {
                role = lib.mkOption {
                    description = "Role / User of the table";
                    type = types.str;
                };
                serviceUnits = lib.mkOption {
                    description = "Services that requires the database. A dependency service will be created.";
                    type = types.listOf types.str;
                    default = [];
                };
            };
        };
        s3Access = types.submodule {
            options = {
                keyID = lib.mkOption {
                    description = "Identifier of the key";
                    type = types.str;
                };
                serviceUnits = lib.mkOption {
                    description = "Services that requires the database. A dependency service will be created.";
                    type = types.listOf types.str;
                    default = [];
                };
            };
        };



}
