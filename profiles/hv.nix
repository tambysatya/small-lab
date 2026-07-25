
/* Standard configuration shared by all hypervisors */

{config, pkgs, ...}:

{
	imports = [ ./default.nix ];
	environment.systemPackages = [pkgs.multipath-tools]; #kpartx
	networking.nameservers = ["193.51.152.152" "193.51.152.153"]; # DNS of the university
}
