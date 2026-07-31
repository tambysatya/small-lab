{lib, inputs, infra, registry, vmname, vmconf, pkgs, config,...}:

let 
    sec = import ../registry/lib/security.nix {inherit inputs lib vmconf vmname infra;};
    s3lib = import ./lib.nix {inherit lib pkgs config;};
    servicenames = lib.concatMap (v: v.use-s3) (lib.attrValues registry.vms);
    accesses = lib.concatMap (v: registry.services.${v}.S3Accesses) servicenames;
    secrets = lib.map 
                    (args: let name = args.fst;
                               access = args.snd;
                            in {
                                "${name}-${access.bucket}-s3-id.key" = {
                                    path = "/run/secrets/${name}-s3-id.key";
                                    reload = ["garage.service"];
                                    owner = "garage";
                                };
                                "${name}-${access.bucket}-s3.key" = {
                                    path = "/run/secrets/${name}-s3.key";
                                    reload = ["garage.service"];
                                    owner = "garage";
                                };

                            })
                    (lib.lists.zipLists servicenames accesses);

in {
config = lib.mkIf 
            (builtins.elem "garage" vmconf.services)
            (lib.mkMerge [
                    (lib.mkMerge (lib.mapAttrsToList (sec.generateSecret "garage") (lib.foldl' lib.recursiveUpdate {} secrets)))
                    { 
                        services.garage = 
                        {
                            enable = true;
                            package = pkgs.garage_2; 
                            settings = 
                            {
                                data_dir = "/srv/data";
                                metadata_dir = "/srv/meta";
                                rpc_bind_addr = "[::]:3901";
                                rpc_secret_file = config.sops.secrets."garage-rpc.key".path;
                                replication_factor = 1;
                                s3_api = 
                                {
                                    api_bind_addr = "127.0.0.1:3900"; # localhost because not encrypted
                                        s3_region = "garage";
                                    root_domain = "s3.${infra.domain}";
                                };
                                admin = {
                                    api_bind_addr = "127.0.0.1:3903"; # localhost because not encrypted
                                    admin_token_file = config.sops.secrets."garage-admin.key".path;
                                    metrics_token_file =  config.sops.secrets."garage-metrics.key".path;
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
                            after = ["garage-permissions.service"];
                            requires = ["garage-permissions.service"];
                        };

                        systemd.services.garage-permissions = {
                            description = "Garage volumes permissions";
                            wantedBy = ["multi-agent.target"];

                            after = [
                                "srv-meta.mount"
                                "srv-data.mount"
                            ];
                            requires = [
                                "srv-meta.mount"
                                "srv-data.mount"
                            ];

                            serviceConfig.Type = "oneshot";
                            script = ''
                                chown -R garage:garage /srv/meta
                                chown -R garage:garage /srv/data
                            '';
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
                            script = lib.concatStringsSep "\n" 
                                            [s3lib.bootstrapNode
                                             (lib.concatMapStringsSep "\n" 
                                                  (args: s3lib.generateAccess args.fst args.snd) 
                                                  (lib.lists.zipLists servicenames accesses))];
                        };
                    }
        ]);
}
