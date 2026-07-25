{lib, ...}:
{
  imports = [./modules/infra];

  config.infra = {
    domain = "local.fr";
    dns = ["8.8.8.8"];
    gateway = "172.31.61.1";
    root_ssh_pubkeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBFJ0VbL229lf3V3SwchD5HadUrDGPKjXRi+dQW45+03 rudy@DESKTOP-VPA2ETG"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFPgnJdPz9RB0O+G8fsz+jjs9g+Bk3GDi1pMA5YneTgT tamby@BrahmsHost"

    ];
    hosts = {
      cpuhost1 = {
        ipAddress = "172.31.62.200";
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
        memory = 4096;
        additionalDisks = [{src="/dev/sdb"; dst="vdb"; bind = "/medias/test"; fsType="xfs";}];

        ipAddress = "172.31.61.200";
        services = ["ldap" "keycloak" "step-ca"];
      };
    };
  };

}


/*
   {

   infra = {
   domain = "local.lphi.umontpellier.fr";
   dns = [...];

   admins = {
   sat = "ssh...";
   rudy = "ssh...",
   };
   vms = {
   identity = {
   host_ip = "...";
   ip = "...";
   services = ["ldap" "keycloak"];
   };
   };

   services = {
   step-ca = {

   };
   };
   }

   }
 */
