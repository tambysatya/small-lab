{inputs, lib, infra, registry, pkgs, ...}:

let
    gen = import ./gen-secrets.nix {inherit inputs lib infra pkgs;};

    #all containers names (key = "ct-vmname-service")
    ctnames = lib.concatLists (
                    lib.mapAttrsToList (vmname: vmconf: 
                        lib.map (service: "ct-${vmname}-${service}") vmconf.containers) infra.vms);
    # all vm + containers identities
    generate_all_ages = lib.concatMapStringsSep "\n"
                            (name: gen.generate_age name)
                            ((builtins.attrNames infra.vms) ++ ctnames);
in
{
    main = pkgs.writeShellApplication {
            name = "gen-secrets";
            runtimeInputs = [
                pkgs.age
                pkgs.openssl
                pkgs.sops
            ];
            text = ''
                    set -x
                    ${generate_all_ages}
            '';
    };
}
