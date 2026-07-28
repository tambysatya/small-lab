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
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};

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
                            (lib.evalModules {
                                    specialArgs = {inherit inputs lib pkgs infra vmname vmconf;};
                                    modules = [
                                        ./modules/registry
                                        ./modules/garage/register.nix
                                        ./modules/keycloak/register.nix
                                        ./modules/openldap/register.nix
                                        ./modules/postgres/register.nix
                                        ./modules/step-ca/register.nix
                                    ];
                                }).config.infra-services.registry)
                        infra.vms);
                            
       configs = lib.mapAttrs
                    (vmname: vmconf:
                        lib.nixosSystem {
                            inherit system; 
                            specialArgs = {
                                inherit inputs infra registry vmname vmconf;
                            };
                            modules = [./profiles/vm.nix];
                        })
                    infra.vms;
#      configs = lib.mapAttrs 
#                  (vmname: vmconf: 
#                    mkSystem 
#                        infra 
#                        registry 
#                        vmname vmconf 
#                        [ 
#                            ./profiles/vm.nix 
#                        ])
#                    infra.vms;

    in {
      generators = {
        terranix = terranix-generator; 
      };
      nixosConfigurations = registry;

      terranixConfigurations =
        terranix-generator infra-config.infra;

      debugPhase1 = registry;
      debugPhase2 = configs; 
      devShells.${system}.default = let pkgs = nixpkgs.legacyPackages.${system};
							in pkgs.mkShell {
								packages = [pkgs.sops pkgs.age pkgs.opentofu pkgs.terranix pkgs.boxes
                            pkgs.openldap # for slappaswd
									    inputs.secret-provisioner.packages.${system}.default];

							};


    };



}

