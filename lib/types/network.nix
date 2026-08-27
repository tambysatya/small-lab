{lib,inputs,...}:

let
    libtypes = lib.types;
    types = libtypes;
    
in {

    ip = lib.mkOption {
        description = "Ip address";
        type = types.str;
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
    tcpProtocol = lib.mkOption {
        description = "Endpoint protocol. Use TCP if the protocol is not listed.";
        type = types.enum 
                    ["tcp"
                     "postgres" "s3" "http" "https"];
        default = "tcp";
    };
    udpProtocol = lib.mkOption {
        description = "Endpoint protocol. Use UDP if the protocol is not listed.";
        type = types.enum 
                    ["udp" "dns"];
        default = "udp";
    };

    
}
