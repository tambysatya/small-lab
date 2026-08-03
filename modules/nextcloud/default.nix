{ config, lib, pkgs, infra, vmname, vmconf, ... }:

# https://danubedata.ro/blog/nextcloud-s3-compatible-primary-storage-2026

let
    infralib = import ../infra/lib.nix {inherit lib vmconf vmname;};
in {

    config = lib.mkIf (infralib.runsService "nextcloud")
    {
        networking.firewall.allowedTCPPorts = [80];
        services.nextcloud = {
            enable = true;	
            https = true; /*IMPORTANT IF HTTPS*/
            home = "/var/lib/nextcloud";
            hostName = "nextcloud.${infra.domain}";
            #phpPackage = lib.mkForce (pkgs.php83.withExtensions ({ all, enabled }: enabled ++ [ all.smbclient ]));

            maxUploadSize = "100G";

            config.adminuser = "admin";
            config.adminpassFile = "/run/secrets/nextcloud-admin.key";
            config.dbtype = "pgsql";
            config.dbhost = "postgres.${infra.domain}:5432";
            config.dbuser = "nextcloud";
            config.dbpassFile = "/run/secrets/nextcloud-nextcloud-db.key";
            
            occ = ["user:report"];

            settings = {
                maintenance_window_start = 0;
                maintenance_window_end = 3;
                trusted_domains = [
                    "nextcloud.${infra.domain}"	
                ];
                trusted_proxies = [
                    #"162.38.243.60"
                    infra.subnet
                    
                ];
                overwritehost = "nextcloud.${infra.domain}";	
                overwriteprotocol = "https";

                objectstore = {
                    class = "\\OC\\Files\\ObjectStore\\S3";
                    arguments = {
                            timeout = 300;
                            connect_timeout = 300;
                            concurrency = 5;
                            uploadPartSize = 524288000;
                            putSizeLimit = 524288000;
                    };
                };
            };
            config.objectstore.s3 = {
                  enable = true;
                  bucket = "nextcloud";
                  region = "garage";
                  #autocreate = true;
                  verify_bucket_exists = true;
                  key = builtins.readFile "${infra.secrets-path}/plain/tokens/nextcloud-nextcloud-s3-id.key"; #Key ID #TODO
                  secretFile = "/run/secrets/nextcloud-nextcloud-s3.key";

                  hostname = "s3.${infra.domain}";
                  useSsl = true;
                  port = 443;
                  usePathStyle = true;
            };
        };

        systemd.services.nextcloud-setup = {
            wants = [
                "network.target"
            ];

            after = [
                "network.target"
            ];
            serviceConfig = { 
                ExecStartPre = "${pkgs.netcat}/bin/nc -z postgres.${infra.domain} 5432"; # wait for the database to be up²
                Restart = "on-failure";
                RestartSec = "30s"; #TODO put a condition (like touch a file) to avoid running this at every startup
            };
            environment = {
                PGSSLMODE = "require";
            };
        };

    /*
        systemd.services.nextcloud-wait-postgres = {
          description = "Wait for PostgreSQL";

          after = [
            "network-online.target"
          ];

          requires = [
            "network-online.target"
          ];

          serviceConfig = {
            Restart = "on-failure";
            RestartSec = "10s";
            Type = "oneshot";
            ExecStart = "${pkgs.netcat}/bin/nc -z postgres.local.lphi.umontpellier.fr 5432"; #TODO parametrize the url
          };
        };
        systemd.services.nextcloud-setup = {
          requires = [
            "nextcloud-wait-postgres.service"
          ];

          after = [
            "nextcloud-wait-postgres.service"
          ];

        };
    */

    };

}
