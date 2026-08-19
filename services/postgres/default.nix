
{inputs, infra, registry, vmname, vmconf, config, lib, pkgs,...}:

let 

    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit inputs lib infra;};
    infralib = import "${inputs.self.outPath}/lib/infra" {inherit lib vmconf vmname;};
    sec = import "${inputs.self.outPath}/lib/compiler/security.nix" {inherit inputs lib vmconf vmname infra;};
    dbaccesses = lib.concatMap (v: registry.services.${v}.dbAccesses) servicenames; #list of dbAccesses in the infrastructure
    servicenames =  lib.filter (srv: 
                                  let srvconf = registry.services.${srv};
                                  in (srvconf.dbAccesses != []) #the service requests DB
                                  && !((srvconf.hosts.containers == []) && srvconf.hosts.vms == [])) # the services is actually hosted
                        (builtins.attrNames registry.services);

    users = lib.map (access: 
                        {
                            name = access.role;
                            ensureDBOwnership = true; # creates a database of the same name #TODO
                            ensureClauses = { login = true; };
                        }) dbaccesses;
    tables = lib.map (access: access.table) dbaccesses;

    secret = {
        names = lib.map vars.db_key dbaccesses;
        owner = "postgres";
        reload = ["postgres.service"];
    };
    
in {

    config = lib.mkIf (infralib.runsService "postgres")
        (lib.mkMerge [
            (sec.generateSecret secret)
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
                        ssl_cert_file = vars.ssl_crt_path "postgres.${infra.domain}";
                        ssl_key_file = vars.ssl_key_path "postgres.${infra.domain}";
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

                    };

                    script = lib.concatStringsSep "\n"
                                    (lib.concatMap 
                                        (args: let name = args.fst;
                                                   access = args.snd;
                                        in [
                                            # TODO - removed custom base name
                                           # ''
                                           #     ${pkgs.postgresql}/bin/psql -d ${access.table} \
                                           #         -c "GRANT ALL PRIVILEGES ON DATABASE ${access.table} TO ${access.role};"
                                           # '' 
                                            ''
                                                  PASSWORD="$(< /run/secrets/db-${name}-${access.table}.key)"
                                                  ${pkgs.postgresql}/bin/psql -U postgres \
                                                    -c "ALTER ROLE ${access.role} WITH PASSWORD '$PASSWORD';"
                                            ''

                                            #''${pkgs.postgresql}/bin/psql -d postgres -f /run/secrets/${name}-${access.table}-db.key''
                                        ])
                                        (lib.lists.zipLists servicenames dbaccesses));


                };
            }
        ]);

}
