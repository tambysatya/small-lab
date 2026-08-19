/* Basic type definition */
{lib,...}:
let inherit (lib) types;
in
{

    sslCertificate = types.submodule {
        options = {
            reload = lib.mkOption {type = types.listOf types.str;};
            owner = lib.mkOption {type = types.str; default = "root";};
        };
    };

    secret = types.submodule {
        options = {
              names = lib.mkOption {
                description = "The list of filenames composing this secret";
                type = types.listOf types.str;
                example = ["nextcloud-admin.key" "nextcloud-db.key"];
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
                default = "0400";
              };
              kind = lib.mkOption {
                description = "Specifies how the secret should be generated using openssl rand during the deployement";
                type = types.submodule {
                        options = {
                            provider = lib.mkOption{
                                description = "Specifies which external tool should be used. Use null if the generation should not be done by small-lab";
                                type = types.nullOr (types.enum ["openssl" "step"]);
                                default = null;
                            };
                            providerArgs = lib.mkOption {
                                description = "Extra args passed to the provider for the secret generation.";
                                type = types.attrs;
                                default = {};
                            };
                        };
                    };
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
                extraNginxConfig = lib.mkOption {
                    description = "Extra config passed to the reverse proxy";
                    type = types.attrs;
                    default = {};
                };
            };
        };
        dbAccess = types.submodule {
            options = {
                owner = lib.mkOption {
                    description = "Owner of the database key";
                    type = types.str;
                    default = "root";
                };
                role = lib.mkOption {
                    description = "Role / User of the table";
                    type = types.str;
                };
                table = lib.mkOption {
                    description = "Tables to be created";
                };
                reload = lib.mkOption {
                    description = "Services that requires the database.";
                    type = types.listOf types.str;
                    default = [];
                };
            };
        };
        s3Access = types.submodule {
            options = {
                owner = lib.mkOption {
                    description = "Owner of the S3 key";
                    type = types.str;
                    default = "root";
                };
                bucket = lib.mkOption {
                    type = types.str;
                };
                reload = lib.mkOption {
                    description = "Services that requires the database.";
                    type = types.listOf types.str;
                    default = [];
                };
            };
        };
        volume = types.submodule { # Persistent volumes
            options = {
                owner = lib.mkOption {
                    description = "Owner of the directory";
                    type = types.str;
                    default = "root";
                };
                path = lib.mkOption {
                    description = "Path of the persistent directory";
                    type = types.str;
                    example = "/var/lib/docker/storage";
                };
                reload = lib.mkOption {
                    description = "Services that requires the volume.";
                    type = types.listOf types.str;
                    default = [];
                };
                modes = lib.mkOption {
                    description = "Permissions of the directory";
                    type = types.str;
                    default = "0700";
                };
            };
        };
        userID = types.ints.positive;



}
