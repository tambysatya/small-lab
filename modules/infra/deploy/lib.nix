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
in utils // {
    inherit mkSopsCert mkSopsS3 mkSopsDB mkSopsLDAP;
}
