
{inputs, lib, config, ... }:
let
types = import "${inputs.self.outPath}/lib/registry/types" { inherit inputs lib; };

in

{
    options.registry.services = lib.mkOption {
        internal = true;
        type = types.attrsOf types.serviceConfig;
        description = "Resources required by the services (generated during phase1)";
        default = {};
    };
    options.registry.vms = lib.mkOption {
        internal = true;
        type = types.attrsOf types.vmConfig;
        default = {};
    };
        
}

