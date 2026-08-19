{inputs, lib, infra,...}:
let
    register = import ./register.nix {inherit inputs lib infra;};
in {
    inherit (register) registerSecret registerCertificate registerEndpoints registerDBAccess registerS3Access registerVolume registerUser;
}
