
{inputs, lib, config, ... }:
let
  types = import "${inputs.self.outPath}/lib/registry/types" { inherit inputs lib; };
in

{
    options.registry = lib.mkOption {
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
                    global = lib.mkOption {
                        description = "Global informations of the desired state."; #MUST BE CHECKED BEFORE VALIDATING MIGRATIONS TODO
                        type = types.submodule {
                            options = {
                                users = lib.mkOption { #UID mappings
                                    internal = true;
                                    description = "Unique UID/GID across the entire infrastructure";
                                    type = types.attrs;
                                    default = {};
                                    example = {postgres= {uid=10001; gid=10001;}; nextcloud={uid=10002; gid=10002;};};
                                };
                            };
                        };
                    };
                };
            };
    };
}

