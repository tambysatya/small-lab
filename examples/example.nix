{path, ...}:
{
  #imports = [inputs.small-lab.nixosModules.infra];
  config.infra.topology = {
/*
    flakePath = path;
    secretsPath = ".secrets";
    caURL = "ca.local.fr";
*/
    domain = "local.fr";
    vmSubnet = "192.168.1.0/24";
    dns = ["8.8.8.8" "8.8.4.4"];
    gateway = "172.31.61.1";
    rootSSHPublicKeys = [
    ];
    services = {
        "keycloak-main" = "keycloak";
        "stepca-main" = "step-ca";
        "openldap-main" = "openldap";
        "garage-main" = "garage";
        "postgres-main" = "postgres";
        "nextcloud-main" = "nextcloud";
    };
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
        ip = "192.168.1.200";
        #services = ["step-ca" "openldap"];
        services = ["keycloak-main" "stepca-main" "openldap-main"];
        persistentVolumes.disks = [
            {
                src="/dev/pvhdd/ldap"; 
                mount = {dir="/var/lib/openldap/data"; fsType="xfs"; options = ["nofail"];};
            }
        ];

      };
      storage = {
        host = "cpuhost1";
        vcpu = 24;
        memory = 8000;
        persistentVolumes.disks = [
            {
                src="/dev/pvhdd/s3"; 
                mount = {dir="/srv/data"; fsType="xfs"; options=["nofail"];};
            }
            {
                src="/dev/ssd/s3_metadatas";
                mount = {dir="/srv/meta"; fsType="xfs"; options=["nofail"];};
            }
        ];

        ip = "192.168.1.201";
        services = ["garage-main"]; 
      };
      postgres = {
        host = "cpuhost1";
        vcpu = 4;
        memory = 8000;
        persistentVolumes.disks = [
            {
                src="/dev/ssd/postgres";
                mount = {dir="/var/lib/postgresql"; fsType="xfs"; options=["nofail"];};
            }
        ];

        ip = "192.168.1.202";
        containers = ["postgres-main"]; 
        #services = ["postgres-main"]; 
      };
      apps = {
        host = "cpuhost1";
        vcpu = 8;
        memory = 16000;

        ip = "192.168.1.203";
        #services = ["nextcloud"]; 
        containers = ["nextcloud-main"]; 
        persistentVolumes.qcows = [
            {
                name = "persistent";
                size = 100 * 1024*1024; # 100M
                mount = {
                    dir = "/srv/persistent";
                    fsType = "ext4";
                    options = ["default"];
                };
                mapping = [ 
                        {vol = "config"; sys = "/var/lib/nextcloud/config";}
                        {vol = "data"; sys = "/var/lib/nextcloud/data";}
                ];
            }
        ];
      };

    };
  };

}

