

/* Standard configuration shared by all VMs */

{
	imports = [ ./default.nix 
		   ../modules/console.nix # allows connections from the host using virsh console
                  ];
	services.qemuGuest.enable = true;
}
