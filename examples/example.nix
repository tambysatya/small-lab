{path, ...}:
{
  #imports = [inputs.small-lab.nixosModules.infra];
  config.infra = {
    flakePath = path;
    secretsPath = ".secrets";
    caURL = "ca.local.fr";
    domain = "local.fr";
    vmSubnet = "192.168.1.0/24";
    dns = ["8.8.8.8" "8.8.4.4"];
    gateway = "172.31.61.1";
    rootSSHPublicKeys = [
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
        persistentVolumes.disks = {
            "/var/lib/openldap/data" = {
                src="/dev/pvhdd/ldap"; 
                target = {device="vdb"; fsType="xfs"; options = ["nofail"];};
            };
        };

      };
      storage = {
        host = "cpuhost1";
        vcpu = 24;
        memory = 8000;
        persistentVolumes.disks = {
            "/srv/data" = {
                src="/dev/pvhdd/s3"; 
                target = {device="vdb"; fsType="xfs"; options=["nofail"];};
            };
            "/srv/meta" = {
                src="/dev/ssd/s3_metadatas";
                target = {device="vdc"; fsType="xfs"; options=["nofail"];};
            };
        };

        ipAddress = "192.168.1.201";
        services = ["garage"]; 
      };
      postgres = {
        host = "cpuhost1";
        vcpu = 4;
        memory = 8000;
        persistentVolumes.disks = {
            "/var/lib/postgresql" = {
                src="/dev/ssd/postgres";
                target = {device="vdb"; fsType="xfs"; options=["nofail"];};
            };
        };

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

