

/* Standard configuration shared by all VMs */

{
	imports = [ ./default.nix 
		   ../modules/console.nix # allows connections from the host using virsh console
		   ../modules/sops.nix # secrets managment
                  ];
	services.qemuGuest.enable = true;
}
