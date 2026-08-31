{lib, inputs, config, ...}:

let
    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};

    
    processPersistent =
        srvuid:
        env:
        persistent@{mode, owner, path, reload, shared}:
        let
        in {};

in {
    imports = [./options];
    /*
    config.infra.volumes = {
        perDirectory = utils.mergeAll (libsmapAttrsToList processVM config.infra.topology.vms);
    };
    */
}
