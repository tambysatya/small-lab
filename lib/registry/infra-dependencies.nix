/* Automatizes the creation of services to ensure dependency between services across the network */

{inputs, lib, pkgs, infra, ...}:
let

    mkDBDependencies = access@{role, table, reload,...}: #TODO each tuple role/table should be unique 
        {
            systemd.services."postgres-wait-${role}-${table}" = {
                before = reload;
                requiredBy = reload;
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
                    RestartSec = "30s"; 
                };
            };
        };

in {
    inherit mkDBDependencies;
}
