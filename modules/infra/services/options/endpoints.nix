
/* Exposed endpoints of the service */

{lib,inputs, ...}:
let 
    libtypes = lib.types;
    regtypes = import "${inputs.self.outPath}/lib/registry/types" {inherit lib inputs;};
    types = libtypes // regtypes;

    port = lib.mkOption {
        description = "Port on which the service can be reached. If the service runs within a container the firewall must be oppened";
        type = types.port;
    };
    http_endpoint = types.submodule {
        options = {
            inherit port;
            inherit (types) hostname;
            extraNginxConfig = lib.mkOption {
                description = "Extra config passed to the reverse proxy";
                type = types.attrs;
                default = {};
            };
        };
    };
    endpoint = types.submodule {
        options =  {
            inherit port;
            inherit (types) hostname;
        };
    };
in {
    endpoints = lib.mkOption {
        description = "Various endpoints exposed by the service. If an HTTPs reverse proxy is required, use the endpoint_https section.";
        type = types.submodule {
            options = {
                udp = lib.mkOption {
                    description = "UDP endpoints";
                    type = types.listOf endpoint;
                    default = [];
                };
                tcp = lib.mkOption {
                    description = "TCP endpoints. If the protocol is HTTP, consider registering an HTTP endpoint instead, in order to automatically deploy SSL.";
                    type = types.listOf endpoint;
                    default = [];
                };
                http = lib.mkOption {
                    description = "HTTP endpoints. A reverse proxy exposing HTTPs will be connected on top of it. TLS certifiicates will be automatically managed.";
                    type = types.listOf http_endpoint;
                    default = [];
                };
            };
        };
    };
}
