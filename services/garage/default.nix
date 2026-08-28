{lib, inputs, infra, registry, vmname, vmconf, pkgs, config,...}:

let 
    infralib = import "${inputs.self.outPath}/lib/infra" {inherit lib vmconf vmname;};
    sec = import "${inputs.self.outPath}/lib/compiler/security.nix" {inherit inputs lib vmconf vmname infra;};
    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit inputs lib infra;};

    s3lib = import ./lib.nix {inherit lib pkgs config infra registry inputs;};
    #servicenames = lib.concatMap (v: v.use-s3) (lib.attrValues registry.vms);
    servicenames =  lib.filter (srv: 
                                  let srvconf = registry.services.${srv};
                                  in (srvconf.s3Accesses != []) #the service requests S3
                                  && !((srvconf.hosts.containers == []) && srvconf.hosts.vms == [])) # the services is actually hosted
                        (builtins.attrNames registry.services);
    accesses = lib.concatMap (v: registry.services.${v}.s3Accesses) servicenames;
    
    secret = {
            names = lib.map vars.s3_key accesses; #all access keys
            reload = ["garage.service"];
            owner = "garage";
    };


in {
config = lib.mkIf 
            (infralib.runsService "garage")
            (lib.mkMerge [
                    (sec.generateSecret secret)
                    { 
                        services.garage = 
                        {
                            enable = true;
                            package = pkgs.garage_2; 
                            settings = 
                            {
                                #data_dir = "/srv/data";
                                #metadata_dir = "/srv/meta";
                                rpc_bind_addr = "[::]:3901";
                                rpc_secret_file = config.sops.secrets."garage-rpc.key".path;
                                replication_factor = 1;

                                /* TESTS */
                               # metadata_fsync = false;
                               # data_fsync=false;
                               # compression_level="none";
                               # block_size = "32M";
                               # #############################

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
