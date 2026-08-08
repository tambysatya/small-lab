
# Module description

## Compilation:

Each service declares the resources it needs (secrets, endpoints, postgres bases...). The compilation is split into two phases.

- During the first phase, the compiler summarizes the resources requirements of each services over the infrastructure
- During the second phase, the resources are allocated, e.g. reverse proxys / pNAT rules are built (depending on the type of endpoint), users and secrets are created (if the services is runned inside a container)...


# TODO

- generates IP/hostname correspondance of each service in /etc/hosts  (for each vm)
- custom service config should be decided in "infra.services" in order to avoid infinite recursion
- the bootstrap script should be generated from the inventory

- step-renew increase the refresh rate

- network config in infra + regroup the options by theme 

- build the iso from this module (using the path of the root directory of the private flake, passed in `infra`)

- unify the sources of truth regarding the secrets paths (imho all the packages confs should refer to `sops.secrets.<name>.path`)
