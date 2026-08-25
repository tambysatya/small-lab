{lib, inputs, pkgs, config,...}:
let
    types = lib.types;
    
in
{
    options.infra.outputs = lib.mkOption {
        description = "Generated configurations";
        type = types.submodule {
            options = {
                prod = lib.mkOption {
                    description = "Configuration of machines in production";
                    type = types.attrs;
                };
                test = lib.mkOption {
                    description = "Configuration of testing machines";
                    type = types.attrs;
                };
            };
        };
    };
}
