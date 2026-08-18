/* Compilations steps that are performed on all backends (containers or native) */


{lib, infra, registry, vmConf, config, inputs, pkgs,...}:
let 
    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit lib infra registry inputs;};
    comp = import "${inputs.self.outPath}/lib/compiler" {inherit lib inputs pkgs registry infra vmname;};

    generateUsers:
        vmConf@{services, containers, ...}:
            let allUsers = 
                    builtins.concatLists 
                        (map (name: registry.services."${name}".users) (services ++ containers));
            in {
               users.users = lib.mapAttrs (name: id: name = {uid=id; group=name;}) allUsers;
               users.groups = lib.mapAttrs (name: id: name = {gid=id;}) allUsers;
            };
in {
    config = generateUsers vmConf;
}


