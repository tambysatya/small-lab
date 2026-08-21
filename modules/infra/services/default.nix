{lib, inputs,...}:

let
    options = import ./options {inherit lib inputs;};
in {
   options.infra.services = lib.mkOption {
        description = "Services resources";
        type = lib.types.attrsOf options.service;
   };
}
