
{inputs, infra, vmname, vmconf, config, lib, pkgs,...}:

{

    config = {  
        networking.firewall.allowedTCPPorts = [5432];
        services.postgresql = {
            enable = true;
            enableTCPIP = true;

            authentication = ''
                local all all peer
                hostssl all all all scram-sha-256
                '';
            ensureUsers = [
            {
                name="nextcloud";
                ensureDBOwnership = true;
                ensureClauses = {
                    login = true;
                };
            }
            ];
            ensureDatabases = [
                "nextcloud"
            ];

            settings = {
                password_encryption = "scram-sha-256";
                ssl = true;
                ssl_cert_file = config.services.step-renew.certs."postgres.${infra.domain}".cert;
                ssl_key_file = config.services.step-renew.certs."postgres.${infra.domain}".key;
                ssl_ca_file = "/etc/root_ca.crt";
            };
        };
        systemd.services.postgresql-nextcloud-password = {
            description = "Configure Nextcloud PostgreSQL password";

            after = [ "postgresql-setup.service"];
            requires = [ "postgresql-setup.service" ];
            wantedBy = ["multi-user.target"];

            serviceConfig = {
                Type = "oneshot";
                User = "postgres";

                ExecStart = ''
                    ${pkgs.postgresql}/bin/psql -d postgres -f /run/secrets/nextcloud-db.key
                    '';
            };
        };
    };

}
