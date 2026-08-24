{inputs, lib, infra, registry, pkgs, ...}:

let

    gen = import ./lib {inherit inputs lib pkgs infra;};

    in
{
    main = pkgs.writeShellApplication {
            name = "gen-secrets";
            runtimeInputs = [
                pkgs.age
                pkgs.openssl
                pkgs.openldap
                pkgs.sops
                pkgs.step-cli
            ];
            text = gen.processSecrets;
           };
}
