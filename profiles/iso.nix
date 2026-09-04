{inputs, config, lib, pkgs, path, ...}:

let
in

{
	imports = [   
			../modules/autoinstall
			../services/console.nix
			
		  ];

	nix.settings.experimental-features = ["nix-command" "flakes"]; #enable flakes
	environment.systemPackages = [pkgs.dmidecode 
				                  inputs.disko.packages.${pkgs.system}.disko];

/*
	environment.etc."root_ca.crt".text = builtins.readFile "${path}/.secrets/git/root_ca.crt";
	security.pki.certificateFiles = [
                                       "${infra.flakePath}/${vars.git}/root_ca.crt"
                                       "${infra.flakePath}/${vars.git}/intermediate_ca.crt"
                                    ]; #trust the root-ca

*/
	networking.hostName = "bootstrap-vm";
	environment.etc."nixos".source = builtins.path {
						name = "deploy-flake";
						#path = ./..;
                        path = path;
					};
}
