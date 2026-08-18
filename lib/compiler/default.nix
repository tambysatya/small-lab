{inputs, lib, pkgs, infra, registry, vmname, ...}:
let
    accessors = import ./accessors.nix {inherit inputs lib infra registry;};
    dependencies = import ./infra-dependencies.nix {inherit inputs lib pkgs infra;};
    security = import ./security.nix {inherit inputs lib infra vmname;};
in
{
    inherit (accessors) serviceUsers;
    inherit (dependencies) mkDBDependencies;
    inherit (security) generateSecret generateCertificate generateReverseProxy;
}
