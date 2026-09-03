{inputs, lib, infra, pkgs, ...}:

let

    gen = import ./lib {inherit inputs lib pkgs infra;};

    in
{
    generator = pkgs.writeShellApplication {
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
    mkInstaller = vmsecrets: pkgs.writeShellApplication {
            name = "install-secrets";
            text = gen.mkInstaller vmsecrets;
           };
}
