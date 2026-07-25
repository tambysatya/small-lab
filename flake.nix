{
	description = "Automatic generation of Terraform and NixOS configurations for a small research lab";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
		disko = {
			url = "github:nix-community/disko";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		sops-nix = {
			url = "github:Mic92/sops-nix";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		secret-provisioner = {
			url = "github:tambysatya/secrets-provisioner";
			inputs.nixpkgs.follows = "nixpkgs";
		};
    terranix = {
      url = "github:terranix/terranix";
			inputs.nixpkgs.follows = "nixpkgs";
    };
	};

  outputs = inputs@{nixpkgs,...}:
    let
			system = "x86_64-linux";
			mkSystem = modules: 
					nixpkgs.lib.nixosSystem 
					{
						system = system;
						inherit modules;
						specialArgs = {
							inherit inputs; 
						};
					};
      lib = nixpkgs.lib;
      nixos-generator = (import ./lib/generators/nixos {inherit lib inputs;}).generator;
      terranix-generator = (import ./lib/generators/terranix {inherit lib inputs;}).generator;

      test-inventory = (lib.evalModules 
                          {modules = [
                              "${nixpkgs}/nixos/modules/misc/assertions.nix"
                              ./modules/infra
                              ./example.nix];}).config.infra;
      configs = lib.mapAttrs 
                  (vmName: vmConf: 
                    mkSystem [(nixos-generator test-inventory vmName vmConf)])
                  test-inventory.vms;

    in {
      generators = {
        nixos = nixos-generator; 
        terranix = terranix-generator; 
      };
      nixosConfigurations = configs;

      terranixConfigurations =
        terranix-generator test-inventory;

      debugModule = configs;

    };



}

