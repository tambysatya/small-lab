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

    containerMount = types.submodule {
        options = {
            container = {
                description = "Container name";
                type = types.str;
            };
            src = lib.mkOption {
               description = "Path of the file on the host";
               type = types.str;
            };
            dst = lib.mkOption {
                description = "Where to mount on the container";
                type = types.str;
            };
        };
    };
    bindMount = types.submodule {
        options = {
            src = lib.mkOption {
               description = "Which file to mount";
               type = types.str;
            };
            dst = lib.mkOption {
                description = "Where to mount on the host ";
                type = types.str;
            };
        };
    };
    deployementConfig = types.submodule {
        options = {
            provisioner = lib.mkOption {
                description = "This system is a VM or a container";
                type = types.deployementHostType;

            };
            users = lib.mkOption {
                description = "List of service users to be created";
                type = types.listOf types.user;
                default = [];
            };
            sops = lib.mkOption {
                description = "All files supervised with SOPS";
                type = types.listOf sopsFile;
                default = [];
            };
            sslCertificates = lib.mkOption {
                description = "All SSL certificates to refresh";
                type = types.listOf types.sslCertificate;
                default = [];
            };
            bindMounts = lib.mkOption {
                description = "List of directory that should be bind-mounted";
                type = types.listOf bindMount;
                default = [];
            };
            containerMounts = lib.mkOption {
                description = "List of files passed to a container";
                type = types.listOf containerMount;
                default = [];
            };

        };
    };


        
in
{
    options.infra.deploy.systems = lib.mkOption {
        internal = true;
        description = "Intermediate representation of a virtual machine configuration";
        type = types.attrsOf deployementConfig;
    };

}
