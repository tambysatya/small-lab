/* Exposed API to register modules informations */
{lib,inputs, ...}:
let libtypes = lib.types;
    infratypes = import "${inputs.self.outPath}/lib/types" {inherit lib inputs;};
    filestypes = import ./files.nix {inherit lib inputs;};
    linkstypes = import ./links.nix {inherit lib inputs;};
    endpointstypes = import ./endpoints.nix {inherit lib inputs;};
    types = libtypes // infratypes // filestypes // endpointstypes // linkstypes;

    user = types.submodule {
        options = {
            name = lib.mkOption {
                description = "Username. A group will be created with the same name";
                type = types.str;
            };
            uid = lib.mkOption {
                description = "Identifier of the user. A group will be created with the same ID";
                type = types.ints.positive;
            };
        };
    };
    persistentDirectory = types.submodule { # Persistent volumes
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
            mode = lib.mkOption {
                description = "Permissions of the directory";
                type = types.str;
                default = "0700";
            };
        };
    };
    service = types.submodule {
            options = {
                users = lib.mkOption {
                    description = "List of service users";
                    type = types.listOf user;
                };
                persistent = lib.mkOption {
                    description = "Persistent directories, managed by the service. The infrastructure must explicitely declare a persistent storage for each of them";
                    type = types.listOf persistentDirectory;
                };
                inherit (types) files endpoints;
                deployements = lib.mkOption {
                    description = "List of environment where the service is currently deployed";
                    type = types.listOf types.deployementEnvironment;
                    default = [];
                };
                links = lib.mkOption {
                    description = "Dependencies across the other services of the infrastructure";
                    type = types.links;
                };
            };
    };

in
{
   options.infra.services = lib.mkOption {
        description = "Services resources";
        type = lib.types.attrsOf service;
   };

}
