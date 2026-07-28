{lib, inputs, config, infra, vmname, vmconf, pkgs,...}:


let 
    reg = import infra-services/lib/register.nix {inherit inputs lib vmname infra;};
    secrets = {
		/* API keys */
		"nextcloud_s3_id.key" = {path = "/var/lib/garage/nextcloud_s3_id.key";};
		"nextcloud_s3.key" = {path = "/var/lib/garage/nextcloud_s3.key";};
		/* Admin secrets */
		"garage-rpc.key" = {path = config.services.garage.settings.rpc_secret_file;};
		"garage-admin.key" = {path = config.services.garage.settings.admin.admin_token_file;};
		"garage-metrics.key" = {path = config.services.garage.settings.admin.metrics_token_file;};
	};
    endpoints = [
        {
            host = "s3.${infra.domain}";
            port = 3900;
        }
        {
            host = "s3-admin.${infra.domain}";
            port = 3903;
        }
    ];

in {

    config = lib.mkIf (builtins.elem "garage" vmconf.services)
                (lib.mkMerge [
                    (reg.registerSecrets "garage" "garage" ["garage.service"] secrets)
                    (reg.registerEndpoints "garage" endpoints)
                    { 
                        services.garage = 
                        {
                            enable = true;
                            package = pkgs.garage_2; 
                            settings = 
                            {
                                #data_dir = "/medias/s3";
                                #metadata_dir = "/medias/s3_metadatas";

                                rpc_bind_addr = "[::]:3901";
                                rpc_secret_file = "/var/lib/garage/rpc-secret";
                                replication_factor = 1;
                                s3_api = 
                                {
                                    api_bind_addr = "127.0.0.1:3900"; # localhost because not encrypted
                                    s3_region = "garage";
                                    root_domain = "s3.${infra.domain}";
                                };
                                admin = {
                                    api_bind_addr = "127.0.0.1:3903"; # localhost because not encrypted
                                    admin_token_file = "/var/lib/garage/garage-admin.key";
                                    metrics_token_file = "/var/lib/garage/garage-metrics.key";
                                };
                            };
                        };

                        users.users.garage = {
                          isSystemUser = true;
                          group = "garage";
                          home = "/var/lib/garage";
                          createHome = true;
                        };
                        users.groups.garage = {};


                        systemd.services.garage = {
                          serviceConfig = {
                            DynamicUser = false;
                            User = "garage";
                            Group = "garage";

                            StateDirectory = "garage";
                          };

                        };

                        systemd.services.garage-bootstrap = {
                            description = "Bootstrap the configuration of garage (bucket creation and keys assignments)";
                            after = ["garage.service"];
                            requires = ["garage.service"];
                            wantedBy = ["multi-user.target"];
                            serviceConfig = {
                                Type = "oneshot";
                                StateDirectory = "garage";
                                Restart = "on-failure";
                                RestartSec = "30s";
                            };
                            script = ''
                                set -euo pipefail
                                
                                if [ ! -f "/var/lib/garage/bootstrap-done" ]; then
                                    echo "Bootstrap garage"

                                    NODEID=`${pkgs.garage_2}/bin/garage node id`
                                    SHORT_NODEID=''${NODEID:0:16}
                                    if ! ${pkgs.garage_2}/bin/garage layout show | grep -q $SHORT_NODEID; then
                                        ${pkgs.garage_2}/bin/garage layout assign -z dc1 -c 1G $NODEID
                                        ${pkgs.garage_2}/bin/garage layout apply --version 1
                                    else
                                        echo "Skipping layout creation"
                                    fi

                                    if ! ${pkgs.garage_2}/bin/garage bucket info nextcloud-bucket; then
                                        echo "Creating nextcloud bucket"
                                        ${pkgs.garage_2}/bin/garage bucket create nextcloud-bucket
                                    else
                                        echo "Skipping bucket creation"
                                    fi

                                    if ! ${pkgs.garage_2}/bin/garage key info nextcloud-key; then
                                        echo "Creating nextcloud key"
                                        ${pkgs.garage_2}/bin/garage key import --yes \
                                            $(cat  ${config.sops.secrets."nextcloud_s3_id.key".path}) \
                                            $(cat  ${config.sops.secrets."nextcloud_s3.key".path}) \
                                            -n nextcloud-key
                                        ${pkgs.garage_2}/bin/garage bucket allow \
                                            --read \
                                            --write \
                                            --owner \
                                            nextcloud-bucket \
                                            --key nextcloud-key
                                    else
                                        echo "Skipping key creation [key already exists]"
                                    fi

                                    echo "Bootstrap done";

                                    touch /var/lib/garage/bootstrap-done
                                fi
                            '';

                        };

                    }
                ]);
                

}
