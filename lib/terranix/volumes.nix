
{lib,inputs, infra, registry, ...}:

let 
    utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};

    compileVMVolumes =
        vmname: vmconf:
            {
                resource.libvirt_volume = generateRootQcow vmname vmconf // generateAdditionalQcow vmname vmconf;
                resource.libvirt_domain."${vmname}".devices.disks = attachVolumes vmname vmconf;
            };

    generateQcow =
        vmname: vmconf: 
        {name, size, persistentP ? false, ...}:
            let host = vmconf.host;
            in {
                    "${vmname}_${name}"= {
                        name = "${vmname}_${name}";
                        pool = "\${libvirt_pool.default_${host}.name}";
                        capacity = size;
                        provider = "libvirt.${host}";
                        lifecycle.prevent_destroy = persistentP;
                    };
                };
    generateRootQcow=
        vmname: vmconf: generateQcow vmname vmconf {name="root"; size=20*1024*1024*1024;};
    generateAdditionalQcow = 
        vmname: vmconf:
            let qcows = infra.vms.${vmname}.persistentVolumes.qcows;
            in utils.mergeAll 
                    (map 
                        ({name, size,...}: 
                            generateQcow vmname vmconf {inherit name size; persistentP = true;})
                        qcows);

    attachVolumes = 
        vmname: vmconf: 
            let 
                vols = registry.vms.${vmname}.attachedVolumes;
                qcows = lib.filter ({deviceType,...}: deviceType == "qcow") (builtins.attrValues vols);
                disks = lib.filter ({deviceType,...}: deviceType == "disk") (builtins.attrValues vols);

            in map (attachQCow vmname vmconf) qcows
            ++ map attachDisk disks
            ++ attachIsoAndRoot vmname vmconf;

    attachIsoAndRoot =
        vmname: vmconf:
            [
              { /* Custom Live Install */
                device = "cdrom";
                source = {
                  file = {file = "\${libvirt_volume.iso_${vmconf.host}.path}";};
                };
                target = {dev = "sda"; bus = "sata";};
                readonly = true;
              }
              { /* Volume "/"  */
                source = {
                  volume = {
                    volume = "\${libvirt_volume.${vmname}_root.name}";	
                    pool = "\${libvirt_pool.default_${vmconf.host}.name}";
                  };
                    
                };
                target = {dev = "vda"; bus="virtio";};
              }
            ];
    attachQCow = 
        vmname: vmconf:
        vol@{hostDevice, vmDevice,...}:
            { 
                source = {
                  volume = {
                    volume = "\${libvirt_volume.${hostDevice}.name}";	
                    pool = "\${libvirt_pool.default_${vmconf.host}.name}";
                  };
                    
                };
                target = {dev = vmDevice; bus="virtio";};
            };
    attachDisk = 
        vol@{hostDevice, vmDevice, ...}:
            {
                source = {
                  block = {
                    dev = hostDevice;
                  };
                };
                target = {dev = vmDevice; bus="virtio";};
                driver = {
                  name = "qemu";
                  type = "raw";
                  cache = "none";
                  io = "native";
                  discard = "unmap";
                    
                };
            };

in {
    inherit compileVMVolumes;
}
