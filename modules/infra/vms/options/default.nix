{lib, inputs, pkgs, config, ...}:

let
    libtypes = lib.types;
    infratypes = import "${inputs.self.outPath}/lib/types" {inherit lib inputs;};
    types = libtypes // infratypes;

    sopsFile = types.submodule {
        options = {
            inherit (types) filename owner reload;
            mode = types.filemode;
        };
    };
   
    vmRequirements = types.submodule {
        options = {
            users = lib.mkOption {
                description = "Concatenation of all the service users";
                type = types.listOf types.user;
            };
            store = lib.mkOption {
                description = "Concatenation of the stores of all services";
                type = types.store;
            };
            links = lib.mkOption{
                description = "Concatenation of the links of all services";
                type = types.links;
            };
            endpoints = lib.mkOption {
                description = "List of endpoints exposed by the VM";
                type = types.endpoints;
            };
            persistent = lib.mkOption {
                description = "Persistent directories";
                type = types.listOf types.persistentDirectory;
            };
            containers = lib.mkOption {
                description = "Containers configuration";
                type = types.attrsOf vmRequirements;
                default = {};
            };
        };

   };
    
    
    vm = types.submodule {
        options = {
            requirements = lib.mkOption {
                description = "Concatenation of the requirements of all services";
                type = vmRequirements;
            };
            users = lib.mkOption {
                description = "List of service users to be created";
                type = types.listOf types.user;
                default = [];
            };
            sopsFiles = lib.mkOption {
                description = "All files supervised with SOPS";
                type = types.listOf sopsFile;
                default = [];
            };
            sslCertificates = lib.mkOption {
                description = "All SSL certificates to refresh";
                type = types.listOf types.sslCertificate;
            };
        };
    };

in
{
    options.infra.vms = lib.mkOption {
        internal = true;
        description = "Intermediate representation of a virtual machine configuration";
        type = types.attrsOf vm;
    };
}
