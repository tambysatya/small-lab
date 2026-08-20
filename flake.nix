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

    terranix-generator_fun = args:
        let conf = compileModule args;
        in (import ./lib/terranix {inherit lib inputs; inherit (conf) infra registry; }).generator;
    compileModule = # A SINGLE FUNCTION TO RULE THEM ALL
        {inventory, extraArgs ? {}}:
           (lib.evalModules {
               specialArgs = {inherit inputs;} // extraArgs;
               modules = [
                  "${nixpkgs}/nixos/modules/misc/assertions.nix"
                  ./modules/infra
                  ./modules/registry
                  inventory
                ];
           }).config; 

    compileInfra = args: (compileModule args).infra;
    compileRegistry = args: (compileModule args).registry;

    nixos-generator = args@{inventory, extraArgs ?{}}: 
        let conf = compileModule args; 
            configs = lib.mapAttrs
                            (vmname: vmconf:
                                lib.nixosSystem {
                                    inherit system; 
                                    specialArgs = {
                                        inherit inputs vmname vmconf;
                                        inherit (conf) infra registry;
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
                            conf.infra.vms;

        in configs;

        extraArgs = {path=inputs.self.outPath;};


        compileGenSecrets = 
            args:
                let conf = compileModule args;
                    script =(import tools/secrets-generator/main.nix 
                                {inherit inputs lib pkgs;
                                 inherit (conf) infra registry;}).main;
                in {
                    packages.${system}.gen-secrets = script;
                    apps.${system}.gen-secrets = {
                        type = "app";
                        program = lib.getExe script;
                    };
                };
                            

    

        
        compileTerranix = 
            args:
                let conf = compileModule args;
                in terranix.lib.terranixConfiguration {
                            inherit system;
                            modules = [
                               ./modules/compiler/terranix 
                            ];
                            extraArgs = {inherit inputs lib; inherit (conf) infra registry;};
                        };
        compileNixos =
            args: nixos-generator args;
        compileIso = 
            args:
                let conf = compileModule args;
                in lib.nixosSystem {
                    inherit system;
                    specialArgs = {inherit inputs lib; inherit (conf) infra registry;};
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

    in compileGenSecrets args //{
      

      lib = {
        inherit compileInfra compileRegistry compileTerranix compileGenSecrets compileNixos compileIso;
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
      terranix = compileTerranix args;
      nixosConfigurations = compileNixos args // {iso = compileIso args;};

      checks.${system} = gen-config-checks inputs;
                   

      #nixosConfigurations = configs;
      #terranixConfigurations = terranix.lib.terranixConfiguration (terranix-generator ./example.nix);

#        terranix.lib.terranixConfiguration {inherit system; 
#                                            modules = [{config = (terranix-generator infra-config.infra);}];};
#
  };


}

