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
	#	secret-provisioner = {
	#		url = "github:tambysatya/secrets-provisioner";
	#		inputs.nixpkgs.follows = "nixpkgs";
	#	};
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

      terranix-generator_fun = (import ./lib/terranix {inherit lib inputs;}).generator;
      terranix-generator  = 
        {inventory, extraArgs ? {}}:
        let 
               infra-config = (lib.evalModules 
                          {
                            modules = [
                              "${nixpkgs}/nixos/modules/misc/assertions.nix"
                              ./modules/infra
                              inventory];
                            specialArgs = {inherit lib;} // extraArgs;
                           }).config;

        in {inherit system; 
            modules = [{config = (terranix-generator_fun infra-config.infra);}];};

      # Generates the infrastructure 
      compile-infra = 
        {inventory, extraArgs ?{}}:
         (lib.evalModules 
              {
                modules = [
                  "${nixpkgs}/nixos/modules/misc/assertions.nix"
                  ./modules/infra
                  inventory];
                specialArgs = {inherit inputs; } // extraArgs;
               }).config.infra;

      compile-registry = infra:
            lib.foldl' 
                lib.recursiveUpdate {}
                 (lib.mapAttrsToList 
                    (vmname: vmconf: 
                        (lib.evalModules {
                            specialArgs = {inherit inputs lib pkgs infra vmname vmconf;};
                            modules = [
                                ./modules/registry
                            ];
                        }).config.registry)
                    infra.vms);


      nixos-generator = args@{inventory, extraArgs ?{}}: 
        let infra = compile-infra args; 
            registry = compile-registry infra;
                                    
            configs = lib.mapAttrs
                            (vmname: vmconf:
                                lib.nixosSystem {
                                    inherit system; 
                                    specialArgs = {
                                        inherit inputs infra registry vmname vmconf;
                                    };
                                    modules = [
                                            ./profiles/vm.nix

                                            ./lib/registry/compiler

                                            ./services/disko-vm.nix
                                            ./services/step-renew
                                            ./services/step-ca
                                            ./services/openldap
                                            ./services/keycloak
                                            ./services/garage
                                            ./services/postgres
                                            ./services/nextcloud

                                        ];
                                })
                            infra.vms;

        in configs;

        extraArgs = {path=inputs.self.outPath;};
        test-infra = compile-infra {
                        inventory = ./examples/example.nix;
                        inherit extraArgs;
                     };
        test-registry = compile-registry test-infra;
        terranix-conf = terranix-generator_fun test-infra;


        compile-gen-secrets = 
            args@{infra, registry}:
                let script =(import tools/secrets-generator/main.nix 
                                {inherit inputs lib pkgs;
                                 inherit (args) infra registry;}).main;
                in {
                    packages.${system}.gen-secrets = script;
                    apps.${system}.gen-secrets = {
                        type = "app";
                        program = lib.getExe script;
                    };
                };
                            

    

        gen-infra = 
            file: 
            flake-path:
                compile-infra {
                    inventory = file;
                    extraArgs = {path=flake-path;};
                };
        gen-registry = 
            file: flake-path: compile-registry (gen-infra file flake-path);
        
        gen-terranix = 
            file: flake-path: terranix.lib.terranixConfiguration {
                            inherit system;
                            modules = [terranix-generator_fun (gen-infra file flake-path)];
                        };
        gen-secrets =
            file: flake-path:
                let infra = gen-infra file flake-path;
                    registry = compile-registry infra;
                in compile-gen-secrets {inherit infra registry;};

        gen-nixos =
            file: file-path: nixos-generator {inventory = file; extraArgs = {path=file-path;};};

            

        

    in compile-gen-secrets {infra = test-infra; registry=test-registry;} //{
     # generators = {
     #   terranix = terranix-generator; 
     #   nixos = nixos-generator;
     #   infra = compile-infra;
     #   registry = compile-registry;
     # };
      lib = {
        inherit gen-infra gen-registry gen-terranix gen-secrets gen-nixos;
      };

      /*
      packages.${system} = {
         gen-secrets = gen-secrets.main;
      };
      apps.${system} = {
            gen-secrets = {
                type = "app";
                program = lib.getExe gen-secrets.main;
            };
      };
      */

      infra = test-infra;
      registry = test-registry;
      #terranix = terranix;
      terranix = terranix.lib.terranixConfiguration {
                                inherit system;
                                modules = [{config=terranix-conf;}];
                            };
      nixosConfigurations = gen-nixos ./examples/example.nix inputs.self.outPath;
                   

      #nixosConfigurations = configs;
      #terranixConfigurations = terranix.lib.terranixConfiguration (terranix-generator ./example.nix);

#        terranix.lib.terranixConfiguration {inherit system; 
#                                            modules = [{config = (terranix-generator infra-config.infra);}];};
#
  };


}

