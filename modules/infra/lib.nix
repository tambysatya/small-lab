{lib, vmconf, vmname,...}:

let hostsService = service:
        builtins.elem service (vmconf.services ++ vmconf.containers);

in {
    
    inherit hostsService;
}
