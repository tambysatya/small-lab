{lib, inputs, pkgs, config,...}:
let
    types = lib.types;

    
in
{
    options.infra.outputs = lib.mkOption {
        description = "Generated configurations";
        type = types.attrs;
    };
}
