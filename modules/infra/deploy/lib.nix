{lib, inputs, ...}:

let
    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};
    mkSopsCert = 
        cert@{hostname,owner, reload,...}:
        let crt = "${hostname}.crt";
            key = "${hostname}.key";
            mkSops = name: {filename=name; inherit owner reload; mode="0400";};
        in [(mkSops crt) (mkSops key)];
    mkSopsS3 = access:
                    [
                        {filename=utils.s3_key_id access; inherit (access) owner reload; mode="0400";}
                        {filename=utils.s3_key access; inherit (access) owner reload; mode="0400";}
                    ];
    mkSopsDB = access: {filename=utils.db_key access; inherit (access) owner reload; mode="0400";};
    mkSopsLDAP = access: {inherit (access) filename owner reload; mode = "0400";};



    envIP = config: env: config.infra.deploy.systems.${utils.ageUID env}.ip;
    envHostIP = config: env:  # Retrives the IP of the host vm if the env is a container
        if env.type == "vm"
            then envIP config env
            else config.infra.deploy.systems.${env.host.vm}.ip;

    hostHasContainers = config: env:
        let host = if env.type == "vm" then env.host else env.host.vm;
        in config.infra.topology.vms.${host}.containers != [];

in utils // {
    inherit mkSopsCert mkSopsS3 mkSopsDB mkSopsLDAP;
    inherit envIP envHostIP hostHasContainers;
}
