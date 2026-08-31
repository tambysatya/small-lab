{lib, inputs, ...}:

let
    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};
    certToSecret = 
        cert@{hostname,owner, reload,...}:
        let crt = "${hostname}.crt";
            key = "${hostname}.key";
            mkSecret = name: {filename=name; inherit owner; mode="0400";};
        in [(mkSecret crt) (mkSecret key)];
    s3ToSecret = access:
                    [
                        {filename=utils.s3_key_id access; inherit (access) owner reload; mode="0400";}
                        {filename=utils.s3_key access; inherit (access) owner reload; mode="0400";}
                    ];
    dbToSecret = access: {filename=utils.db_key access; inherit (access) owner reload; mode="0400";};
    ldapToSecret = access: {inherit (access) filename owner reload; mode = "0400";};



    envIP = config: env: config.infra.deploy.systems.${utils.envUID env}.ip;
    envHostIP = config: env:  # Retrives the IP of the host vm if the env is a container
        if env.type == "vm"
            then envIP config env
            else config.infra.deploy.systems.${env.host.vm}.ip;

    hostHasContainers = config: env:
        let host = if env.type == "vm" then env.host else env.host.vm;
        in config.infra.topology.vms.${host}.containers != [];

in utils // {
    inherit certToSecret s3ToSecret dbToSecret ldapToSecret;
    inherit envIP envHostIP hostHasContainers;
}
