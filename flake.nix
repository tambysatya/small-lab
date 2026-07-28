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
    mkSystem = infra: registry: vmname: vmconf: modules: 
            nixpkgs.lib.nixosSystem 
            {
                system = system;
                inherit modules;
                specialArgs = {
                    inherit inputs infra vmname vmconf; 
                };
            };
      lib = nixpkgs.lib;
      nixos-generator = (import ./lib/generators/nixos {inherit lib inputs;}).generator;
      terranix-generator = (import ./lib/generators/terranix {inherit lib inputs;}).generator;

      infra-config = (lib.evalModules 
                          {modules = [
                              "${nixpkgs}/nixos/modules/misc/assertions.nix"
                              ./modules/infra
                              ./example.nix];}).config;
      infra = infra-config.infra;

      registry = lib.foldl' 
                    lib.recursiveUpdate
                    {}
                    (lib.mapAttrsToList 
                        (vmname: vmconf: 
                            (nixpkgs.lib.nixosSystem {
                                    inherit system;
                                    specialArgs = {inherit inputs lib infra vmname vmconf;};
                                    modules = [
                                        ./modules/infra-services
                                        ./modules/garage.nix
                                        ./modules/keycloak.nix
                                        ./modules/openldap.nix
                                        ./modules/postgres.nix
                                        ./modules/step-ca.nix

                                        ./modules/step-renew
                                    ];
                                }).config.infra-services.registry)
                        infra.vms);
                            
      configs = lib.mapAttrs 
                  (vmname: vmconf: 
                    mkSystem 
                        infra 
                        registry 
                        vmname vmconf 
                        [ 
                            infra-config
                            # modules/infra-services/lib/processRegisters.nix
                        ])
                    infra.vms;

    in {
      generators = {
        nixos = nixos-generator; 
        terranix = terranix-generator; 
      };
      nixosConfigurations = registry;

      terranixConfigurations =
        terranix-generator infra-config.infra;

      debugModule = registry;
      devShells.${system}.default = let pkgs = nixpkgs.legacyPackages.${system};
							in pkgs.mkShell {
								packages = [pkgs.sops pkgs.age pkgs.opentofu pkgs.terranix pkgs.boxes
                            pkgs.openldap # for slappaswd
									    inputs.secret-provisioner.packages.${system}.default];

							};


    };



}

