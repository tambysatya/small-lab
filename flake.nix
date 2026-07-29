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

  outputs = inputs@{nixpkgs, terranix, ...}:

    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
      pkgs = nixpkgs.legacyPackages.${system};

      terranix-generator = (import ./lib/generators/terranix {inherit lib inputs;}).generator;
      nixos-generator = extra: inventory:
        let 
              infra-config = (lib.evalModules 
                          {
                            modules = [
                              "${nixpkgs}/nixos/modules/misc/assertions.nix"
                              ./modules/infra
                              inventory];
                            specialArgs = {inherit extra;};
                           }).config;
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
                                                ./modules/nextcloud/register.nix
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
                                    modules = [./profiles/vm.nix
                                               ./modules/disko-vm.nix
                                        ];
                                })
                            infra.vms;
                iso = lib.nixosSystem {
                        modules = [
                               "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
                               ./profiles/iso.nix
                        ];
                        inherit system;
                        specialArgs = {inherit inputs;};
                    };

        in configs // {inherit iso;};

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
                                        ./modules/nextcloud/register.nix
                                    ];
                                }).config.infra-services.registry)
                        infra.vms);
                            
       configs = nixos-generator inputs ./example.nix;

    in {
      generators = {
        terranix = terranix-generator; 
        nixos = nixos-generator;
      };
      nixosConfigurations = configs;
      terranixConfigurations =

        terranix.lib.terranixConfiguration {inherit system; 
                                            modules = [{config = (terranix-generator infra-config.infra);}];};

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

