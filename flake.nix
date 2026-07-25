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
    in {
      lib = {
        generateNixOS = import ./lib/generators/nixos {inherit lib;}.generator;
        generateTerranix = import ./lib/generators/terranix {inherit lib;}.generator;
      };
    };



}

