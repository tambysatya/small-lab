
{inputs, infra, registry, vmname, vmconf, config, lib, pkgs,...}:

let sec = import ../registry/lib/security.nix {inherit inputs lib vmconf vmname infra;};
    servicenames = lib.concatMap (v: v.use-db) (lib.attrValues registry.vms); #list of services requesting a db access
    dbaccesses = lib.concatMap (v: registry.services.${v}.dbAccesses) servicenames; #list of dbAccesses in the infrastructure
    users = lib.map (access: 
                        {
                            name = access.role;
                            # ensureDBOwnership = true; # creates a database of the same name
                            ensureClauses = { login = true; };
                        }) dbaccesses;
    tables = lib.map (access: access.table) dbaccesses;
    secrets = lib.map 
                    (args: let  name = args.fst;
                                access = args.snd;
                                secname = "${name}-${access.table}-db.key";
                           in {
                               "${secname}"  = { 
                                   path = "/run/secrets/${secname}.key";
                                   owner = "postgres";
                                   reload = ["postgres.service"];
                                };
                             })
                    (lib.lists.zipLists servicenames dbaccesses);
    

in {

    config = lib.mkIf (builtins.elem "postgres" vmconf.services)
        (lib.mkMerge [
         (lib.mkMerge (lib.mapAttrsToList (sec.generateSecret "postgres") (lib.foldl' lib.recursiveUpdate {} secrets))) # generates the secrets for each service
        {  
            networking.firewall.allowedTCPPorts = [5432];
            services.postgresql = {
                enable = true;
                enableTCPIP = true;

                authentication = ''
                    local all all peer
                    hostssl all all all scram-sha-256
                    '';
                ensureUsers = users; 
                ensureDatabases =tables; 

                settings = {
                    password_encryption = "scram-sha-256";
                    ssl = true;
                    ssl_cert_file = config.services.step-renew.certs."postgres.${infra.domain}".cert;
                    ssl_key_file = config.services.step-renew.certs."postgres.${infra.domain}".key;
                    ssl_ca_file = "/etc/root_ca.crt";
                };
            };
            systemd.services.postgresql-password = {
                description = "Configure PostgreSQL passwords and permissions";

                after = [ "postgresql-setup.service"];
                requires = [ "postgresql-setup.service" ];
                wantedBy = ["multi-user.target"];

                serviceConfig = {
                    Type = "oneshot";
                    User = "postgres";
                    ExecStart = lib.concatStringsSep "\n"
                                    (lib.concatMap 
                                        (args: let name = args.fst;
                                                   access = args.snd;
                                        in [
                                            ''${pkgs.postgresql}/bin/psql -d ${access.table} -c "GRANT ALL PRIVILEGES ON DATABASE ${access.table} TO ${access.role};"'' 
                                            ''${pkgs.postgresql}/bin/psql -d postgres -f /run/secrets/${name}-${access.table}-db.key''
                                        ])
                                        (lib.lists.zipLists servicenames dbaccesses));


                };
            };
        }
    ]);

}
