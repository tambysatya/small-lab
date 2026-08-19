
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
                        internal = true;
                        type = types.attrsOf types.vmConfig;
                        default = {};
                    };
                };
            };
    };
}

