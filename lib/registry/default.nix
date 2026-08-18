{inputs, lib, infra, vmname, vmconf, ...}:
let
    register = import ./register.nix {inherit inputs lib infra vmname vmconf;};
    accessors = import ./accessors.nix {inherit inputs lib infra};
in {
    inherit (register) registerSecret registerCertificate registerEndpoints registerDBAccess registerS3Access registerVolume;
    inherit (accessors) serviceUsers;
}
