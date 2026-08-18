{inputs, lib, infra, vmname, vmconf, ...}:
let
    register = import ./register.nix {inherit inputs lib infra vmname vmconf;};
in {
    inherit (register) registerSecret registerCertificate registerEndpoints registerDBAccess registerS3Access registerVolume registerUser;
}
