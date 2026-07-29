
{ lib, config, ... }:
let
  types = import lib/types { inherit lib; };
in

{
    options.infra-services = {
        enable = lib.mkEnableOption "Enable centralized services managment";
        registry = lib.mkOption {
                #type = types.attrsOf types.serviceConfig;
                type = types.submodule {
                    options = {
                        services = lib.mkOption {
                                internal = true;
                                type = types.attrsOf types.serviceConfig;
                                description = "Resources required by the services (generated during phase1)";
                                default = {};
                        };
                        vms = lib.mkOption {
                                type = types.attrsOf types.vmConfig;
                                description = "Resources required by the vms (generated during phase 1)";
                                default = {};
                        };
                    };
                };
        };
    };
}

