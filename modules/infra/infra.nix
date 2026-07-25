{ lib, config, ... }:

let
  types = import ./types.nix { inherit lib; };
in
{
  /* Options definitions */
  options.infra = {
    domain = lib.mkOption {
      type = types.str;
      example = "infra.local";
    };
    ca = lib.mkOption {
      type = types.caConfig;
      description = "CA authority configuration";
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
          };
        }
      );
    };
    vms = lib.mkOption {
      type = types.attrsOf types.vmConf;
    };

    services = lib.mkOption {
      type = types.attrsOf types.serviceConfig;
    };
  };

  /* Module configuration */
  config.infra = {
    ca = {
      url = lib.mkDefault "ca.${config.infra.domain}";
    };
  };
}
