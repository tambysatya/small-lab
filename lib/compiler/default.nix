{inputs, lib, pkgs, infra, registry, vmname, ...}:
let
    dependencies = import ./infra-dependencies.nix {inherit inputs lib pkgs infra;};
    security = import ./security.nix {inherit inputs lib infra vmname;};
in
{
    inherit (dependencies) mkDBDependencies;
    inherit (security) generateSecret generateCertificate generateReverseProxy;
}
