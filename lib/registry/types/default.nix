{lib,...}:

let
    types = lib.types;

in
rec {

    /* Basic types constructors */
    filename = lib.mkOption {
        description = "Name of the file";
        type = types.str;
    };

    owner = lib.mkOption {
        description = "Username of the owner";
        type = types.str;
        default = "root";
    };
    reload = lib.mkOption {
        description = "Services to be reloaded";
        type = types.listOf types.str;
        default = [];
    };
    dirmode = lib.mkOption {
        description = "Permissions of the directory";
        type = types.str;
        default = "0700";
    };
    filemode = lib.mkOption {
        description = "Permissions of the file";
        type = types.str;
        default = "0400";
    };

    opensslSize = lib.mkOption {
        description = "Length of the string to be generated using openssl rand";
        type = types.ints.positive;
        default = 64;
    };
    opensslType = lib.mkOption {
        description = "Type of the string to be generated using openssl rand";
        type = types.enum ["base64" "hex"];
    };
    hostname = lib.mkOption {
        description = "Host domain";
        type = types.str;
        example = "auth.local.fr";
    };

    /* Types constructors of various (potentially secrets) files that can be exposed by a service*/

    plaintext = types.submodule { #will be world readable
            options = {
                inherit filename opensslSize opensslType;
            };
    };
    password = types.submodule {
            options = {
                inherit filename owner reload opensslSize opensslType;
            };
    };
    sslCertificate = types.submodule {
            options = {
                inherit hostname owner reload;
            };
    };
    s3access = types.submodule {
            options = {
                inherit owner reload;
                bucket = lib.mkOption{
                    description = "Name of the bucket";
                    type = types.str;
                    example = "nextcloud-bucket";
                };
            };
    };
    postgresAccess = types.submodule {
            options = {
                inherit owner reload;
                database = lib.mkOption {
                    description = "Name of the database. So far, the role (= user) name does necessarily match the database"; #TODO
                    type = types.str;
                    example = "nextcloud";
                };
            };
    };
    ldapSSHA = types.submodule {
            options = {
                inherit filename owner opensslSize opensslType;
            };
    };


}
