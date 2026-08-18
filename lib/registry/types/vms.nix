{inputs, lib,...}:

let types = lib.types;
    infratypes = import "${inputs.self.outPath}/lib/infra/types.nix" {inherit lib;};
    regtypes = import "${inputs.self.outPath}/lib/registry/types/register.nix" {inherit lib;};
in

{
    vmConfig = types.submodule {
        options = {
            use-db = lib.mkOption {
                type = types.listOf infratypes.serviceType;
                default = [];
                description = "List of services requesting a POSTGRESQL access";
            };
            use-s3 = lib.mkOption {
                type = types.listOf infratypes.serviceType;
                default = [];
                description = "List of services requesting a S3 access";
            };
            use-volumes = lib.mkOption {
                type = types.listOf regtypes.volume;
                default = [];
                description = "List of volumes required to be available on the VM.";
            };
            users = lib.mkOption {
                type = types.attrsOf regtypes.userid;
                default = {};
                description = "Mapping User-UserID of the Services users of the VM";
            };
        };
    };
}
    
