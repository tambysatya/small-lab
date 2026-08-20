{inputs, lib, pkgs, infra, registry, vmname, ...}:
let
    dependencies = import ./infra-dependencies.nix {inherit inputs lib pkgs infra;};
    security = import ./security.nix {inherit inputs lib infra vmname;};
    volumes = import ./volumes.nix {inherit inputs lib pkgs infra registry;};
in
{
    inherit (dependencies) mkDBDependencies;
    inherit (security) generateSecret generateCertificate generateReverseProxy;
    inherit (volumes) compileVolumes;
}
