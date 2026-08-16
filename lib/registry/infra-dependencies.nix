/* Automatizes the creation of services to ensure dependency between services across the network */

{inputs, lib, pkgs, infra, ...}:
let
     mkDBDependencies = reload: 
        lib.mkMerge 
            (lib.map 
                (service:
                    {
                        systemd.services."postgres-wait-${lib.removeSuffix ".service" service}" = {
                            description = "Waiting for postgres to be reachable [dependency of service]...";
                            wants = [
                                "network.target"
                            ];
                            after = [
                                "network.target"
                            ];
                            before = [service];
                            requiredBy = [service];
                            serviceConfig = { 
                                Type = "oneshot";
                                ExecStart = 
                                    "${pkgs.netcat}/bin/nc -z postgres.${infra.domain} 5432"; # wait for the database to be up²
                                Restart = "on-failure";
                                RestartSec = "30s"; 
                            };
                        };
                    })
            reload);

    /*
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
                    ExecStart = 
                        "${pkgs.netcat}/bin/nc -z postgres.${infra.domain} 5432"; # wait for the database to be up²
                    Restart = "on-failure";
                    RestartSec = "30s"; 
                };
            };
        };
    */

in {
    inherit mkDBDependencies;
}
