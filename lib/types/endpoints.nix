
/* Exposed endpoints of the service */

{lib,inputs, ...}:
let
    libtypes = lib.types;
    network = import ./network.nix {inherit lib inputs;};
    types = libtypes // network;

in
rec {
    
    tcpEndpoint = types.submodule {
        options = {
            inherit (types) hostname port;
            proto = types.tcpProtocol;
            needTLS = lib.mkOption {
                description = "A reverse proxy assuming TLS termination will be created"; 
                type = types.bool;
                default = false;
            };
            proxyExtraConfig = lib.mkOption {
                description = "Extra attrset transfered to the proxy configuration";
                type = types.attrs;
                default = {};
            };
        };
    };

    udpEndpoint = types.submodule {
        options = {
            inherit (types) hostname port udpProtocol;
        };
    };  
    endpoints = types.submodule {
        options = {
            udp = lib.mkOption {
                description = "UDP endpoints.";
                type = types.listOf udpEndpoint;
                default = [];
            };
            tcp = lib.mkOption {
                description = "TCP endpoints.";
                type = types.listOf tcpEndpoint;
                default = [];
            };
        };
    };
}
