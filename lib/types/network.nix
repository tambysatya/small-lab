{lib,inputs,...}:

let
    libtypes = lib.types;
    types = libtypes;
    
in rec {

    ip = lib.mkOption {
        description = "Ip address";
        type = types.str;
        default = "127.0.0.1";
    };
    hostname = lib.mkOption {
        description = "Host domain";
        type = types.str;
        example = "auth.local.fr";
    };
    port = lib.mkOption {
        description = "Port on which the service can be reached.";
        type = types.port;
    };
    tcpList = ["tcp" "postgres" "s3" "http" "https"];
    tcpProtocol = lib.mkOption {
        description = "Endpoint protocol. Use TCP if the protocol is not listed.";
        type = types.enum tcpList; 
        default = "tcp";
    };
    udpProtocol = lib.mkOption {
        description = "Endpoint protocol. Use UDP if the protocol is not listed.";
        type = types.enum 
                    ["udp" "dns"];
        default = "udp";
    };

    isTCP = proto: builtins.elem proto tcpProtocol;
    
}
