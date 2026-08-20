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
      utils = import ./lib/utils.nix {inherit lib;};
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

    compileModule = # A SINGLE FUNCTION TO RULE THEM ALL
        {inventory, extraArgs ? {}}:
           lib.evalModules {
               specialArgs = {inherit inputs;} // extraArgs;
               modules = [
                  "${nixpkgs}/nixos/modules/misc/assertions.nix"
                  ./modules/infra
                  ./modules/registry
                  inventory
                ];
           }; 

    compileInfra = args: (compileModule args).config.infra;
    compileRegistry = args: (compileModule args).config.registry;


      /*
      compile-registry = infra:
            utils.mergeAll
                 (lib.mapAttrsToList 
                    (vmname: vmconf: 
                        (lib.evalModules {
                            specialArgs = {inherit inputs lib pkgs infra vmname vmconf;};
                            modules = [
                                ./modules/registry
                            ];
                        }).config.registry)
                    infra.vms);
      */


      nixos-generator = args@{inventory, extraArgs ?{}}: 
        let infraConf = compileModule args; 
            infra = infraConf.config.infra;
            registry = infraConf.config.registry;
            configs = lib.mapAttrs
                            (vmname: vmconf:
                                lib.nixosSystem {
                                    inherit system; 
                                    specialArgs = {
                                        inherit inputs infra registry vmname vmconf;
                                    };
                                    modules = [
                                            ./profiles/vm.nix

                                            ./modules/compiler

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
                            

    

        
        gen-terranix = 
            args@{file, flake-path}:
                terranix.lib.terranixConfiguration {
                            inherit system;
                            modules = [
                                {config = terranix-generator_fun (compileInfra args);}
                            ];
                        };
        gen-secrets =
            args@{inventory, extraArgs}:
                let conf = (compileModule args).config;
                in compile-gen-secrets {inherit (conf) infra registry;};

        gen-nixos =
            args: nixos-generator args;
        gen-iso = 
            args:
                let infra = compileInfra args;
                in lib.nixosSystem {
                    inherit system;
                    specialArgs = {inherit inputs infra;};
                    modules = [
                        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
                        ./profiles/iso.nix
                    ];
                };
                
         gen-config-checks =
            flake-inputs:
                    builtins.mapAttrs
                        (_: nixosConfig:
                            nixosConfig.config.system.build.toplevel)
                        flake-inputs.self.nixosConfigurations;
                
            

            

        
        #args = {file=./examples/example.nix; flake-path=inputs.self.outPath;};
        args = {inventory = ./examples/example.nix; extraArgs = {path=inputs.self.outPath;};};

    in gen-secrets args //{
      

      lib = {
        inherit compileInfra compileRegistry gen-terranix gen-secrets gen-nixos gen-iso;
        inherit gen-config-checks;
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

      infra = compileInfra args;
      registry = compileRegistry args;
      #infra = gen-infra args;
      #registry = gen-registry args;
      #terranix = gen-terranix args;
      nixosConfigurations = gen-nixos args // {iso = gen-iso args;};

      checks.${system} = gen-config-checks inputs;
                   

      #nixosConfigurations = configs;
      #terranixConfigurations = terranix.lib.terranixConfiguration (terranix-generator ./example.nix);

#        terranix.lib.terranixConfiguration {inherit system; 
#                                            modules = [{config = (terranix-generator infra-config.infra);}];};
#
  };


}

