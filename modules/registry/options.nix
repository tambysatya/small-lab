
{ lib, config, ... }:
let
  types = import ./types.nix { inherit lib; };
in

{
    options.infra-services = {
        enable = lib.mkEnableOption "Enable centralized services managment";
        registry = lib.mkOption {
                        type = types.attrsOf types.serviceConfig;
        };
    };
}

