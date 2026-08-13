
/* Default packages availables everywhere */

{pkgs,...}:

{
	environment.systemPackages = [pkgs.nix-index
				      pkgs.vim pkgs.git
				      pkgs.htop pkgs.wget
				      pkgs.molly-guard
				      pkgs.rxvt-unicode];
}
