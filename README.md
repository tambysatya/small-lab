
# Module description

## Compilation:

Each service declares the resources it needs (secrets, endpoints, postgres bases...). The compilation is split into two phases.

- During the first phase, the compiler summarizes the resources requirements of each services over the infrastructure
- During the second phase, the resources are allocated, e.g. reverse proxys / pNAT rules are built (depending on the type of endpoint), users and secrets are created (if the services is runned inside a container)...


# TODO

- ldap : persistent volume
- generates IP/hostname correspondance of each service in /etc/hosts  (for each vm)
- custom service config should be decided in "infra.services" in order to avoid infinite recursion
- the bootstrap script should be generated from the inventory

- services should specify what are their DB password file. IF done, the flake should create the proper initialize service on the POSTGRES vm

- containers lib: maybe, instead of defining the reverse proxys IN each service module, define a function that browses the services/containers of each VM and generates the reverse proxies. This would allow the possibility to transparently choose if a service should be containerized or not.

- initialize the database password from the provisioning machine (in order to avoid storing all the passwords on the database/S3 servers) (how to maintain it declaratively ?) TODO

- step-renew increase the refresh rate

- network config in infra + regroup the options by theme 
- containers: each containers has a SOPS key and decrypt its own secrets

- build the iso from this module (using the path of the root directory of the private flake, passed in `infra`)

- REGISTER should do nothing, every complex steps should be moved in the processing phase (check registerS3 + registerDBACcess)

- unify the sources of truth regarding the secrets paths (imho all the packages confs should refer to `sops.secrets.<name>.path`)
