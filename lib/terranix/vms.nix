{lib,inputs, infra, registry, ...}:

let
  utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};
  vols = import ./volumes.nix {inherit lib inputs infra registry;};

  generateVMDomains = infra: utils.mergeAll
    (lib.mapAttrsToList 
      (vmName: vmConf: 
        generateVMDomain vmName vmConf)
      infra.vms);

  generateVMDomain = vmname: vmconf:
      let token = builtins.readFile "/tmp/${vmname}.token";
          host = vmconf.host;
      in utils.mergeAll [
        (vols.compileVMVolumes vmname vmconf) #Disks generations
        {
             resource.libvirt_domain."${vmname}" = {
                provider = "libvirt.${host}";
                autostart = true;
                running = true; #starts the vm
                sys_info = [
                  {smbios = {
                    system = {entry = [{name = "serial"; value = vmname;}];};
                    chassis = {entry = [{name = "serial"; value = token;}];};
                    };
                  }
                ];
                name = vmname;
                type="kvm";

                memory = vmconf.memory;
                memory_unit = "MiB";
                vcpu = vmconf.vcpu;
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
          }
      ];
in {
  inherit generateVMDomains;
}
