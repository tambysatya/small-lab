{lib,inputs, pkgs, ...}:

let
    types = lib.types // (import "${inputs.self.outPath}/lib/types" {inherit lib inputs;});

    dstPath = filename: ".secrets/plain/${filename}";
    generateSSLString = 
        {filename, opensslSize, opensslType,...}:
        ''
            [[ ! -f ${dstPath filename} ]] && ${lib.getExe pkgs.openssl} rand -${opensslType} ${lib.toString opensslSize} > ${dstPath filename}
        '';
    
    generateS3Access = 
        {bucket, ...}:
        let id = "s3-${bucket}.id";
            key = "s3-${bucket}.key";
        lib.concatMapStringsSep "\n" 
                (filename: generateSSLString {inherit filename; opensslSize=32; opensslType="hex";})
                [id key];
    generatePostgresAccess = 
        {database, ...}: {};

    processSecret = 
        {type, content, recipient}:
        {};
in {
}
