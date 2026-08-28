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

    diskMapping = types.submodule {
        options = {
            host = lib.mkOption {
                description = "Path to the disk on the host";
                type = types.str;
            };
            letter = lib.mkOption {
                description = "Letter corresponding to the device mapping vdX";
                type = types.str;
            };
        };
    };

    bindMount = types.submodule {
        options = {
            what = lib.mkOption {
                description = "Source directory (what to mount). The directory will be created if it does not exists.";
                type = types.str;
            };
            where = lib.mkOption {
                description = "Target directory (where to mount).";
                type = types.str;
            };
            inherit (types) owner reload;
            mode = types.dirmode;
        };
    };

    storage = types.submodule {
        options = {
            mappings = lib.mkOption {
                description = "Mapping between disks on the KVM host and on the virtual machine";
                type = types.listOf diskMapping;
                default = [];
            };
            binds = lib.mkOption {
                description = "Bind mounted directory.";
                type = types.listOf bindMount;
                default = [];
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
            proxy = lib.mkOption {
                description = "Network interactions";    
                type = proxy;
            };
            storage = lib.mkOption {
                description = "Persistent storage  configuration";
                type = storage;
            };

        };
    };

    addr = types.submodule {
        options = {
            inherit (types) ip port;
        };  
    };
    backendEntry = types.submodule {
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
     frontendEntry = types.submodule {
        options = {
            inherit (types) port;
            listen = lib.mkOption {
                description = "Which IP address to listen";
                type = types.str;
                default = "127.0.0.1";
            };
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
            defaultProxy = lib.mkOption {
                description = "IP of the default proxy.";
                type = types.str;
                default = "localhost";
            };
            frontend = lib.mkOption {
                description = "Protocol mapping of the frontend";
                type = types.attrsOf frontendEntry;
                #example = {"postgres.local.fr" = {ip="192.168.1.100"; port=5432;};};
                default = {};
            };
            backend = lib.mkOption {
                description = "Backends locations. Multiple backends can be provided.";
                type = types.attrsOf (types.listOf backendEntry);
                example = {"nextcloud.local.fr" = {ip="localhost"; port=80;};};
                default = {};
                apply = t: lib.mapAttrs (key: l: lib.unique l) t;
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
