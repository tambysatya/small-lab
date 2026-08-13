{path, ...}:
{
  #imports = [inputs.small-lab.nixosModules.infra];
  config.infra = {
    flake-path = path;
    secrets-path = "${path}/secrets";
    caURL = "ca.local.fr";
    domain = "local.fr";
    vm-subnet = "192.168.1.0/24";
    dns = ["8.8.8.8" "8.8.4.4"];
    gateway = "172.31.61.1";
    root_ssh_pubkeys = [
    ];
    hosts = {
      cpuhost1 = {
        ipAddress = "192.168.2.200";
      };
      /*
      backhost = {
        ipAddress = "172.31.72.201";
      };
      */
    };
    vms = {
      identity = {
        host = "cpuhost1";
        vcpu = 4;
        memory = 8000;
        ipAddress = "192.168.1.200";
        services = ["keycloak" "step-ca" "openldap"];
        additionalDisks = [
            {src="/dev/pvhdd/ldap"; dst="vdb"; bind = "/var/lib/openldap/data"; fsType="xfs"; options = ["nofail"];}
        ];

      };
      storage = {
        host = "cpuhost1";
        vcpu = 24;
        memory = 8000;
        additionalDisks = [
            {src="/dev/pvhdd/s3"; dst="vdb"; bind = "/srv/data"; fsType="xfs"; options=["nofail"];}
            {src="/dev/ssd/s3_metadatas"; dst="vdc"; bind = "/srv/meta"; fsType="xfs"; options=["nofail"];}
        ];

        ipAddress = "192.168.1.201";
        services = ["garage"]; 
      };
      postgres = {
        host = "cpuhost1";
        vcpu = 4;
        memory = 8000;
        additionalDisks = [{src="/dev/ssd/postgres"; dst="vdb"; bind = "/var/lib/postgresql"; fsType="xfs"; options=["nofail"];}];

        ipAddress = "192.168.1.202";
        services = ["postgres"]; 
      };
      apps = {
        host = "cpuhost1";
        vcpu = 8;
        memory = 16000;

        ipAddress = "192.168.1.203";
        #services = ["nextcloud"]; 
        containers = ["nextcloud"]; 
      };

    };
  };

}

