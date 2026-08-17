{lib,inputs,...}:

let
  utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};

  generateQcow =
    vmName: vmConf: 
    {name, size, ...}:
        let host = vmConf.host;
        in {
                resource.libvirt_volume."${vmName}_${name}"= {
                    vname = "${vmName}_${name}";
                    pool = "\${libvirt_pool.default_${host}.name";
                    capacity = size;
                    provider = "libvirt.${host}";
                };
            };
  generateRootQcow=
    vmName: vmConf: generateQcow vmName vmConf {name="root"; size=20*1024*1024*1024;};

  # generates the / volume for each VM
  generateRootQcows = infra: utils.mergeAll (lib.mapAttrsToList generateRootQcow infra.vms);

  generateVMDomains = infra: utils.mergeAll 
    (lib.mapAttrsToList 
      (vmName: vmConf: 
        generateVMDomain vmName (generateInstanceFromConf infra vmName vmConf))
      infra.vms);
  generateInstanceFromConf = infra: vmName: vmConf: {token = builtins.readFile "/tmp/${vmName}.token"; config=vmConf;};



  declareDisks = vmInstance: 
    lib.mapAttrsToList (_: {src,target}: 
        {
          source = {
              block = {
                dev = src;
              };
            };
            target = {dev = target.device; bus="virtio";};
            driver = {
              name = "qemu";
              type = "raw";
              cache = "none";
              io = "native";
              discard = "unmap";
            };

       })  vmInstance.config.persistentVolumes.disks;
    generateVMDomain = vmName: vmInstance:
      let token = vmInstance.token;
          vm = vmInstance.config;
          host = vm.host;
          disks = [
              { /* Custom Live Install */
                device = "cdrom";
                source = {
                  file = {file = "\${libvirt_volume.iso_${host}.path}";};
                };
                target = {dev = "sda"; bus = "sata";};
                readonly = true;
              }
              { /*Newly created volume */
                source = {
                  volume = {
                    volume = "\${libvirt_volume.disk_${vmName}.name}";	
                    pool = "\${libvirt_pool.default_${host}.name}";
                  };
                    
                };
                target = {dev = "vda"; bus="virtio";};
              }
          ] ++ declareDisks vmInstance;
      in {
         resource.libvirt_domain."${vmName}" = {
            provider = "libvirt.${host}";
            autostart = true;
            running = true; #starts the vm
            sys_info = [
              {smbios = {
                system = {entry = [{name = "serial"; value = vmName;}];};
                chassis = {entry = [{name = "serial"; value = token;}];};
                };
              }
            ];
            name = vmName;
            type="kvm";

            memory = vm.memory;
            memory_unit = "MiB";
            vcpu = vm.vcpu;
            cpu.mode = "host-passthrough";

            features.acpi = true;
            os = {
              type = "hvm";
              boot_devices = [{dev="hd";} {dev = "cdrom";}];
              type_machine = "q35";
              firmware = "efi";
              sm_bios.mode = "sysinfo";
            };
            devices = {
              interfaces = [
                {
                  source.bridge.bridge= "br0";
                  model.type = "virtio";
                }
              ];
              disks = disks; 
              serials = [
              {
                type="pty";
                source = {path="/dev/pts/0";};
                target = {type="isa-serial"; port=0;};
              }
              ];
              consoles = [{
                type = "pty";
                source = {path = "/dev/pts/0";};
                target = {type="serial"; port=0;};
              }
              ];

            };
          };


      };
in {
  inherit generateRootQcows generateVMDomains;
}
