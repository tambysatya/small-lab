
{inputs, lib, infra, registry,...}:
/* Default configuration on all machines */
let
    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit lib infra inputs registry;};
in {
	imports = [
		   ../services/packages.nix # default packages installed system-wide
    ];

	nix.settings.experimental-features = ["nix-command" "flakes"]; #enable flakes
	security.pki.certificateFiles = [
                                        "${infra.flakePath}/${vars.git}/root_ca.crt"
                                        "${infra.flakePath}/${vars.git}/intermediate_ca.crt"
                                    ]; #trust the root-ca
	environment.etc."root_ca.crt".text = builtins.readFile "${infra.flakePath}/${vars.git}/root_ca.crt";
	environment.etc."intermediate_ca.crt".text = builtins.readFile "${infra.flakePath}/${vars.git}/intermediate_ca.crt";
	programs.vim = {
		enable = true;
		defaultEditor = true;
	};


}
