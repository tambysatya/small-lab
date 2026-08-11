{ lib, config, ... }:

let
types = import ./types.nix { inherit lib; };
in
{
    /* Options definitions */
    options.infra = {
        secrets-path = lib.mkOption {
            description = "root repository of secrets";
            type = types.str;
        };
        caURL = lib.mkOption {
            description = "URL of the CA"; #TODO can be conflictng with the JSON conf
                type = types.str;
        };
        caPort = lib.mkOption {
            description = "Port of the CA"; #TODO can be conflictng with the JSON conf
                default = 8443;
            type = types.port;
        };

        domain = lib.mkOption {
            type = types.str;
            example = "infra.local";
        };

        subnet = lib.mkOption {
            type = types.str;
            example = "10.0.1.0/24";
            description = "Subnet of the vlan";
        };

        dns = lib.mkOption {
            type = types.listOf types.str;
            example = ["8.8.8.8" "8.8.4.4"];
        };
        gateway = lib.mkOption {
            type = types.str;
            description = "Address of the gateway for the default route";
        };
        root_ssh_pubkeys = lib.mkOption {
            type = types.listOf types.str;
            description = "A list of SSH keys that will be allowed to connect as root";
        };
        hosts = lib.mkOption {
            type = types.attrsOf (
                    types.submodule {
                    options = {
                    ipAddress = lib.mkOption {type = types.str;};
                    };});
        };
        vms = lib.mkOption {
            type = types.attrsOf types.vmConf;
        };
    };

}
