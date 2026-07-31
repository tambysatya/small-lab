
{infra,...}:
/* Default configuration on all machines */

{
	imports = [
		   ../modules/packages.nix # default packages installed system-wide
    ];

	nix.settings.experimental-features = ["nix-command" "flakes"]; #enable flakes
	security.pki.certificateFiles = ["${infra.secrets-path}/plain/CA/certs/root_ca.crt"]; #trust the root-ca
	environment.etc."root_ca.crt".text = builtins.readFile "${infra.secrets-path}/plain/CA/certs/root_ca.crt";
	programs.vim = {
		enable = true;
		defaultEditor = true;
	};


}
