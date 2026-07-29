{inputs, config, lib, pkgs, ...}:


{
	imports = [   
			../modules/autoinstall
			../modules/console.nix
			
		  ];

	nix.settings.experimental-features = ["nix-command" "flakes"]; #enable flakes
	environment.systemPackages = [pkgs.dmidecode 
				      inputs.disko.packages.${pkgs.system}.disko];
	environment.etc."root_ca.crt".text = builtins.readFile ../secrets/plain/CA/certs/root_ca.crt;
	security.pki.certificateFiles = [../secrets/plain/CA/certs/root_ca.crt]; #trust the root-ca

	networking.hostName = "bootstrap-vm";
	environment.etc."nixos".source = builtins.path {
						name = "deploy-flake";
						path = ./..;
					};
}
