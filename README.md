
# Module description

## Compilation:

Each service declares the resources it needs (secrets, endpoints, postgres bases...). The compilation is split into two phases.

- During the first phase, the compiler summarizes the resources requirements of each services over the infrastructure
- During the second phase, the resources are allocated, e.g. reverse proxys / pNAT rules are built (depending on the type of endpoint), users and secrets are created (if the services is runned inside a container)...


# TODO

- generates IP/hostname correspondance of each service in /etc/hosts  (for each vm)
- custom service config should be decided in "infra.services" in order to avoid infinite recursion

- step-renew increase the refresh rate
- step-renew: use a service user instead of root

- network config in infra + regroup the options by theme 


- unify the sources of truth regarding the secrets paths (imho all the packages confs should refer to `sops.secrets.<name>.path`)
- unify the source of truth for the IP addresses

- persistence of datas: Two independent tofu states: compute state (destroyable) and storage state (persistent)
- persistence: TODO: handle the case where the file should be mounted in a container


- TODO tests (config works + secrets exists + secrets are properly encrypted + no clash between users)
- logging

- TODO use only vmconf (do not inherit vmnames) to avoid clashes definitions in accesses (e.g. infra.vms.services instead of vmconf.services). This may be helpful to handle containers transparently, since the container is seen as a custom vmconf. => Maybe do not inherit from INFRA entirely (avoid passing the configurations of the other VMs).

- secret-generator: generates only the secrets for the services activated. It is mostly done but not for some strings e.g. keycloak-initial-admin
- secret-generator: maybe rewrite: 1/ the secrets are generated depending on which service is activated IN THE INFRA. 2/ the secrets are encrypted depending on the VM running the service

- users: some usersID are set by their own service. Now we FORCE it to a new value (our) but not sure if this is a good approach TODO

- Move functions process* in modules/compiler into lib/

- Factorize the basic types (with constructors, e.g mkFStypeOption, mkDirOption, ...)
- Sanitize the code:
	+ avoid configs = in order to avoid infinite recursions 
	+ do everything in one step instead of having multiple evalModules
	+ move and regroup the code in order to never have a function editing multiple root fields of config (eg config.users and config.services)


- TODO: store the secrets properly in the registry
- TODO add multiple provisioenrs in step-ca


- TODO: sanitize the code: registry should provide a unified interface to register services informations instead of multiple functions that are mkMerged
- TODO: put a registry.internal.vms."name".config containing the entire config of each vm ? THis could allow us to avoid infinite recursion
- TODO: refactor: config.infra.topology (actual config.infra) + config.infra.services (actual config.registry...)
