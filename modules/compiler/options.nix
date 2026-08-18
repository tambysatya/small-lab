{config,lib,...}:

let
    types = lib.types;
in {
    options = {
        compiler = {
            noEndpoints = lib.mkOption {
                description = "Do not compiles endpoints";
                type = types.bool;
                default = false;
            };
        };
    };
}
