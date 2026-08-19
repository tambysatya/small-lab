/* Compilations steps that are performed on all backends (containers or native) */


{lib, infra, registry, vmname, vmconf, config, inputs, pkgs,...}:
let 
    utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;}; 
    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit lib infra registry inputs;};
    comp = import "${inputs.self.outPath}/lib/compiler" {inherit lib inputs pkgs registry infra vmname;};

    generateUsers = 
        vmconf@{services, containers, ...}:
            let allUsers = 
                    utils.mergeAll
                        (map (name: registry.services."${name}".users) (services ++ containers));
            in {
               users.users = lib.mapAttrs (name: id: {uid=lib.mkForce id; group=name; isSystemUser=true;}) allUsers;
               users.groups = lib.mapAttrs (name: id: {gid=lib.mkForce id;}) allUsers;
            };
in {
    config = generateUsers vmconf;
}


