{lib, infra, registry, vmname, vmconf, inputs, config, ...}:

let
    path = "${inputs.self.outPath}";
    utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};

    qcows = vmconf.persistentVolumes.qcows;
    disks = vmconf.persistentVolumes.disks;
    allMountsEntries =  # The list of the mount entries with the source directory properly built
        builtins.concatLists 
            (lib.mapAttrsToList
                (dir: {target,...}:
                    let mounts = target.mounts;
                    in lib.map
                            (entry: {
                                    what = "${dir}/${entry.what}";
                                    inherit (entry) where type owner mode;
                            })
                            mounts)
                (qcows // disks));
    
    generateSystemdMounts = #bind-mounts the files
        lib.map
            (entry: {
                inherit (entry) what where; 
                options="bind"; 
                type="none";
                after = ["init-volumes.service"];
                requires= ["init-volumes.service"];
            })
            allMountsEntries;

    generateSystemdMountInit =  
        let
            mountpoints = builtins.attrNames (qcows // disks);
            mountservices = builtins.trace mountpoints (lib.map utils.pathToMountUnit mountpoints);
        in{
            "init-volumes.service" = {
               description = "If empty, initializes the volumes before bind-mounting the files and repositories.";
               after = mountservices;
               requires = mountservices;
               script = initializeMountsScript;
               serviceConfig = {
                    Type = "oneshot";
               };
            };
        };

    initializeMountsScript =  # A script that creates the files/directory to be bind-mounted if they does not exist.
        lib.concatMapStringsSep "\n"
            (entry:
                if entry.type == "directory" then 
                        ''
                            if [[ ! -d ${entry.where} ]]; then
                                mkdir -p ${entry.where}
                                chown ${entry.owner} ${entry.where}
                                chmod ${if entry.mode == null then "0700" else entry.mode} ${entry.where}
                            fi
                        ''
                else
                        ''
                            if [[ ! -f ${entry.where} ]]; then
                                touch ${entry.where}
                                chown ${entry.owner} ${entry.where}
                                chmod ${if entry.mode == null then "0600" else entry.mode} ${entry.where}
                            fi
                        ''
                )
            allMountsEntries;

  

in 
{

imports = let path = inputs.self.outPath;
            in [
                inputs.sops-nix.nixosModules.sops
                "${path}/profiles/base.nix"

             ];


config = {
     
              boot.kernelParams = ["console=tty1" "console=ttyS0,115200"];

              boot.loader.systemd-boot.enable = true;
              boot.loader.efi.canTouchEfiVariables = true;
              time.timeZone = "Europe/Paris";
              i18n.defaultLocale = "fr_FR.UTF-8";



              networking = {
                hostName = vmname;
                interfaces.enp1s0 = {
                  useDHCP = false;
                  ipv4 = {
                    addresses = [
                      {address = vmconf.ipAddress; prefixLength = 24;}
                    ];
                    routes = [
                      {address = "0.0.0.0"; via = infra.gateway; prefixLength = 0;}
                    ];
                  };
                };
                nameservers = infra.dns;
              };

              /* Mounts additional disks */
              fileSystems = 
                (utils.mergeAll (lib.mapAttrsToList
                                  (bind: disk: {
                                          "${bind}" = {
                                              device = "/dev/${disk.target.device}";   
                                              fsType = disk.target.fsType;
                                              options = disk.target.options;
                                          };
                                    }) (disks // qcows)));
              systemd.mounts = generateSystemdMounts;
              systemd.services = generateSystemdMountInit;
              services.openssh.enable = true;
              users.users.root.openssh.authorizedKeys.keys = infra.rootSSHPublicKeys;


              networking.firewall = { #TODO
                allowedTCPPorts = [22]; # ++ generateTCPPorts vmconf.services 
                allowedUDPPorts = []; # ++ generateUDPPorts vmconf.services
              };
        };  
}
