{lib, inputs, pkgs, config, ...}:

let
    libtypes = lib.types;
    infratypes = import "${inputs.self.outPath}/lib/types" {inherit lib inputs;};
    types = libtypes // infratypes;
    
    vm = types.submodule {
        options = {
            users = lib.mkOption {
                description = "List of service users to be created";
                type = types.listOf types.user;
            };
            store = lib.mkOption{
                description = "List of files to be added to the store";
                type = types.store;
            };
            links = lib.mkOption{
                description = "List of dependencies across the infrastructure";
                type = types.links;
            };
            endpoints = lib.mkOption {
                description = "List of endpoints exposed by the VM";
                type = types.endpoints;
            };
            containers = lib.mkOption {
                description = "Containers configuration";
                type = vm;
            };
        };
    };

in
{
    options.infra.vms = lib.mkOption {
        internal = true;
        description = "Intermediate representation of a virtual machine configuration";
        type = types.attrsOf vm;
    };
}
