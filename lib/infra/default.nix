{lib, vmconf, vmname,...}:

let hostsService = service:
        builtins.elem service (vmconf.services ++ vmconf.containers);
    runsService = service:
        builtins.elem service vmconf.services;

in {
    
    inherit hostsService runsService;
}
