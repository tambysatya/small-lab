{lib,inputs, pkgs, infra, ...}:

let
    types = lib.types // (import "${inputs.self.outPath}/lib/types" {inherit lib inputs;});
    ssl = import ./ssl.nix {inherit lib inputs pkgs;};
    age = import ./age.nix {inherit lib inputs pkgs;};

    plain = ".secrets/plain";
    git = ".secrets/git";
    keys = ".secrets/keys";
    enc = ".secrets/git/enc";
    dstPath = filename: "${plain}/${filename}";
    generateSSLString = 
        {filename, opensslSize, opensslType,...}:
        ''
            [[ ! -f ${dstPath filename} ]] && ${lib.getExe pkgs.openssl} rand -${opensslType} ${lib.toString opensslSize} \
                                                | tr -d "\n" \
                                                > ${dstPath filename}
        '';
    
    processPassword = 
        recipients:
        sslargs@{filename,...}:
        lib.concatStringsSep "\n"
            [
                (generateSSLString sslargs)
                (lib.concatMapStringsSep "\n" (age.encrypt filename) recipients)
            ];
        
    processS3Access =
        recipients: content@{bucket,...}:
        let id = "s3-${bucket}.id";
            key = "s3-${bucket}.key";
            genString = filename: generateSSLString {inherit filename; opensslSize=32; opensslType="hex";};
        in lib.concatStringsSep "\n"
            [
                (genString id)
                (genString key)
                (lib.concatMapStringsSep "\n" (age.encrypt id) recipients)
                (lib.concatMapStringsSep "\n" (age.encrypt key) recipients)
            ];
    processPostgres = 
        recipients: {database,...}:
        let filename = "db-${database}.key";
        in lib.concatStringsSep "\n"
            [
                (generateSSLString {inherit filename; opensslSize = 64; opensslType = "base64";})
                (lib.concatMapStringsSep "\n" (age.encrypt filename) recipients)
            ];

    processLDAP = 
        recipients: content@{filename,...}:
        lib.concatStringsSep "\n" 
            [
                (generateSSLString content)
                (lib.concatMapStringsSep "\n" (age.encrypt filename) recipients)
                ''
                    cat ${plain}/${filename} \
                    | ${pkgs.openldap}/bin/slappasswd -s -- -h "{SSHA}" \
                    > ${git}/${filename}.ssha
                ''
            ];
    processSSLCert =
        recipients: content@{hostname,...}:
        let
            crt = "${hostname}.crt";
            key = "${hostname}.key";
        in
        lib.concatStringsSep "\n" [
            (ssl.gen_ssl_certificate hostname)
            (lib.concatMapStringsSep "\n" (age.encrypt crt) recipients)
            (lib.concatMapStringsSep "\n" (age.encrypt key) recipients)
        ];
    

    processStep =
        recipients:
        let
            steppath = "${plain}/CA";
            
        in
        lib.concatStringsSep "\n" [
            (lib.concatMapStringsSep "\n" (age.encrypt "intermediate_ca_key") recipients)
            (lib.concatMapStringsSep "\n" (age.encrypt "ca-password.key") recipients)
        ];

    processSecret = 
        {type, content, recipients, ...}:
        {
             "plain" = generateSSLString content;
             "password" = processPassword recipients content;
             "ldapssha" = processLDAP recipients content;
             "postgres" = processPostgres recipients content;
             "s3" = processS3Access recipients content;
             "sslCertificates" = processSSLCert recipients content;
             "step-ca" = processStep recipients; # always generated first
        }.${type};

in {
    processSecrets = 
        ''
            mkdir -p ${plain}
            mkdir -p ${git}
            mkdir -p ${enc}
            mkdir -p ${keys}
            ${lib.concatMapStringsSep "\n" age.generateAge infra.secrets.identities}
            ${ssl.generateCA infra.topology.domain}
            ${lib.concatMapStringsSep "\n" processSecret infra.secrets.allSecrets}
        '';
}
