{ inputs, config, lib, pkgs, infra, registry, vmname, vmconf, ... }:

# https://danubedata.ro/blog/nextcloud-s3-compatible-primary-storage-2026

let
    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit lib infra registry inputs;};
    hostname = "nextcloud.${infra.domain}";
    infralib = import "${inputs.self.outPath}/lib/infra" {inherit lib vmconf vmname;};
in {

    config = lib.mkIf (infralib.runsService "nextcloud")
    {
        networking.firewall.allowedTCPPorts = [443 80];
        services.nginx.clientMaxBodySize = "100G";
        services.nginx.virtualHosts."nextcloud.${infra.domain}" = 
            {
                #forceSSL = true;
                #sslCertificate = "/run/secrets/${hostname}.crt";
                #sslCertificateKey = "/run/secrets/${hostname}.key";
                extraConfig = ''
                        proxy_request_buffering off;
                        proxy_buffering off;
                        proxy_http_version 1.1;
                        proxy_read_timeout 1h;
                        proxy_send_timeout 1h;
                        send_timeout 3600s;

 
                        client_body_timeout 3600s;
                        fastcgi_request_buffering off;
                        fastcgi_read_timeout 3600s;
                    '';
            };

        services.nextcloud = {
            enable = true;	

            #https = true; /*IMPORTANT IF HTTPS*/

            home = "/var/lib/nextcloud";
            hostName = "nextcloud.${infra.domain}";
            #phpPackage = lib.mkForce (pkgs.php83.withExtensions ({ all, enabled }: enabled ++ [ all.smbclient ]));

            maxUploadSize = "100G";

            config.adminuser = "admin";
            config.adminpassFile = config.sops.secrets."nextcloud-admin.key".path;
            config.dbtype = "pgsql";
            config.dbhost = "postgres.${infra.domain}:5432";
            config.dbuser = "nextcloud";
            config.dbpassFile = config.sops.secrets."db-nextcloud-nextcloud.key".path;
            
            occ = ["user:report"];

            phpOptions = {
                upload_max_filesize = "100G";
                post_max_size = "100G";
                max_execution_time = 3600;
                max_input_time = 3600;
                output_buffering = 0;
                #memory_limit = "5G";
                "opcache.enable" = 1;
                "opcache.memory_consumption" = 128;
                "opcache.interned_strings_buffer" = 16;
                "opcache.max_accelerated_files" = 10000;
                "opcache.revalidate_freq" = 1;
                "opcache.save_comments" = 1;
            };
            settings = {
                #instanceid = builtins.readFile "${infra.secretsPath}/plain/nextcloud-instanceid";
                loglevel = 1;
                log_type = "file";
                maintenance_window_start = 0;
                maintenance_window_end = 3;
                trusted_domains = [
                    "nextcloud.${infra.domain}"	
                ];
                trusted_proxies = [
                    #"162.38.243.60"
                    infra.vmSubnet
                    
                ];
                overwritehost = "nextcloud.${infra.domain}";	
                #overwriteprotocol = "https";

               # objectstore = {
               #     class = "\\OC\\Files\\ObjectStore\\S3";
               #     arguments = {
               #             timeout = 300;
               #             connect_timeout = 300;
               #             concurrency = 5;
               #             uploadPartSize = 524288000;
               #             putSizeLimit = 524288000;
               #     };
               # };
            };
            config.objectstore.s3 = {
                  enable = true;
                  bucket = "nextcloud";
                  region = "garage";
                  #autocreate = true;
                  verify_bucket_exists = true;
                  key = builtins.readFile "${infra.flakePath}/${vars.git}/s3-nextcloud_id"; #Key ID #TODO
                  secretFile = config.sops.secrets."s3-nextcloud.key".path;

                  hostname = "s3.${infra.domain}";
                  useSsl = true;
                  port = 443;
                  usePathStyle = true;
            };

            caching.memcached = true;
            caching.redis = true;
            configureRedis = true;
        };

        systemd.services.nextcloud-setup = {
            wants = [
                "network.target"
            ];

            after = [
                "network.target"
            ];
            serviceConfig = { 
                ExecStartPre = 
                    "${pkgs.netcat}/bin/nc -z postgres.${infra.domain} 5432"; # wait for the database to be up²
                Restart = "on-failure";
                RestartSec = "30s"; #TODO put a condition (like touch a file) to avoid running this at every startup
            };
            environment = {
                PGSSLMODE = "require";
            };
        };
    };

}
