{lib,inputs, pkgs, infra, ...}:

let
    types = lib.types // (import "${inputs.self.outPath}/lib/types" {inherit lib inputs;});
    ssl = import ./ssl.nix {inherit lib inputs pkgs;};

    plain = ".secrets/plain";
    git = ".secrets/git";
    dstPath = filename: "${plain}/${filename}";
    generateSSLString = 
        {filename, opensslSize, opensslType,...}:
        ''
            [[ ! -f ${dstPath filename} ]] && ${lib.getExe pkgs.openssl} rand -${opensslType} ${lib.toString opensslSize} \
                                                | tr -d "\n" \
                                                > ${dstPath filename}
        '';
    
    generateS3Access = 
        {bucket, ...}:
        let id = "s3-${bucket}.id";
            key = "s3-${bucket}.key";
        in lib.concatMapStringsSep "\n" 
                (filename: generateSSLString {inherit filename; opensslSize=32; opensslType="hex";})
                [id key];
    generatePostgresAccess = 
       {database, ...}:
       generateSSLString {filename = "db-${database}.key"; opensslSize = 64; opensslType="base64";};


    processSecret = 
        {type, content, ...}:
        {
             "plain" = generateSSLString content;
             "password" = generateSSLString content;
             "ldapssha" = generateSSLString content;
             "postgres" = generatePostgresAccess content;
             "s3" = generateS3Access content;
             "sslCertificates" = ssl.gen_ssl_certificate content.hostname;
             "step-ca" = ""; # always generated first
        }.${type};
in {
    processSecrets = 
        ''
            mkdir -p ${plain}
            mkdir -p ${git}
            ${ssl.generateCA infra.topology.domain}
            ${lib.concatMapStringsSep "\n" processSecret infra.secrets}
        '';
}
