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
            env = lib.mkOption {
                description = "This system is a VM or a container";
                type = types.deployementEnvironment;
            };
            ip = lib.mkOption {
                description = "IP address";
                type = types.str;
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
            proxy = lib.mkOption {
                description = "Network interactions";    
                type = proxy;
            };

        };
    };

    addr = types.submodule {
        options = {
            inherit (types) ip port;
        };  
    };
    proxyEntry = types.submodule {
        options = {
            inherit (types) ip port;
            mode = lib.mkOption {
                description = "Proxy mode";
                type = types.enum ["http" "tcp" "udp"];
                default = "tcp";
            };
            extraConf = lib.mkOption {
                description = "Extra configuration passed to the proxy";
                type = types.attrs;
                default = {};
            };
        };
    };
    proxy = types.submodule {
        options = {
            frontend = lib.mkOption {
                description = "Protocol mapping of the frontend";
                type = types.attrsOf proxyEntry;
                #example = {"postgres.local.fr" = {ip="192.168.1.100"; port=5432;};};
                default = {};
            };
            backend = lib.mkOption {
                description = "Backends locations";
                type = types.attrsOf proxyEntry;
                example = {"nextcloud.local.fr" = {ip="localhost"; port=80;};};
                default = {};
            };
        };
    };

    
    location = types.submodule {
        options = {
            env = lib.mkOption {
                description = "Environment of the server";
                type = types.deployementEnvironment;
            };
            inherit (types) port;

        };
    };
    network = types.submodule {
        options = {
            postgres = lib.mkOption {
                description = "List of hosts providing a database";
                type = types.listOf location;
                default = [];
            };
            s3 = lib.mkOption {
                description = "List of hosts providing an S3 access";
                type = types.listOf location;
                default = [];
            };
            ldap = lib.mkOption {
                description = "List of hosts providing an ldap access";
                type = types.listOf location;
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
    options.infra.deploy.network= lib.mkOption {
        internal = true;
        description = "Intermediate representation of the entire network.";
        type = network;
    };

}
