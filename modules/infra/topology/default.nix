{lib, inputs,...}:

let
    options = import ./options {inherit lib inputs;};
in {
   options.infra.topology = lib.mkOption {
        description = "Topology of the infrastructure";
        type = options.topology;
   };
}
