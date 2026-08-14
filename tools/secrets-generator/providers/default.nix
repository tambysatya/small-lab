{inputs, lib, infra, registry, pkgs, ...}:

let
    utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};
    pw = import ./passwords.nix {inherit inputs lib infra registry pkgs;};
    accounts = import ./accounts.nix {inherit inputs lib infra registry pkgs;};
    step = import ./step.nix {inherit inputs lib infra registry pkgs;};
in {
    inherit (pw) processPasswordSecrets;
    inherit (accounts) bootstrap_ldap processS3Secrets processDBSecrets;
    inherit (step) bootstrap_step_ca processSSLCertificates processHTTPEndpoints;

}
