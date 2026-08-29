{lib, inputs, pkgs, config,...}:
let
    types = lib.types;

    /* We need to manually reimplement some options, otherwise the conflict resolution won't allow
       us to define infra.outputs.<name>.config from multiple different places */

    config = types.submodule {
        options ={
            config.imports = lib.mkOption {
                description = "List of imports";
                type = types.listOf (types.either types.str types.path);
                default = [];
            };
            config.sops = lib.mkOption {
                description = "Sops configuration";
                type = types.attrs;
                default = {};
            };
            config.services.step-renew = lib.mkOption {
                description = "Step Renew configuration";
                type = types.attrs;
                default = {};
            };
        };
    };

    
in
{
    options.infra.outputs = lib.mkOption {
        description = "Generated configurations";
        type = types.attrsOf config;
    };}
