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
    utils = import ./lib {inherit lib inputs;};
    pkgs = nixpkgs.legacyPackages.${system};

    terranix-generator_fun = args:
        let conf = compileModule args;
        in (import ./lib/terranix {inherit lib inputs; inherit (conf) infra registry; }).generator;

    compileModule = # A SINGLE FUNCTION TO RULE THEM ALL
        {inventory, extraArgs ? {path = "${inputs.self.outPath}/.secrets";}}:
           (lib.evalModules {
               specialArgs = {inherit inputs lib;} // extraArgs;
               modules = [
                  "${nixpkgs}/nixos/modules/misc/assertions.nix"
                  ./modules/infra
                  inventory
                ];
           });
    compileConfig = args: (compileModule args).config;

    compileAssertions = args: (compileModule args).assertions;
    compileInfra = args: (compileConfig args).infra;
    compileRegistry = args: (compileConfig args).registry;

    nixos-generator = args@{inventory, extraArgs ?{}}: 
        let infra = compileInfra args; 
            vmconfs = lib.filterAttrs 
                            (name: value: infra.deploy.systems.${name}.env.type == "vm")
                            infra.outputs;
            configs = lib.mapAttrs
                            (vmname: vmconf:
                                lib.nixosSystem {
                                    inherit system; 
                                    specialArgs = {
                                        inherit inputs;
                                    };
                                    modules = [

                                        ];
                                })
                            vmconfs;
        in configs;


        compileGenSecrets = 
            args:
                let infra = compileInfra args;
                    script =(import tools/secrets-generator/main.nix 
                                {inherit inputs lib pkgs infra;}).generator;
                in {
                    packages.${system}.gen-secrets = script;
                    apps.${system}.gen-secrets = {
                        type = "app";
                        program = lib.getExe script;
                    };
                };

        compileInstallSecrets = 
            args:
            let infra = compileInfra args;
                build = 
                    name: script: 
                    let prog = pkgs.writeShellApplication 
                        {
                            name = "${name}-install-secrets";
                            text = script;
                        };
                    in {
                        packages.${system}."${name}-install-secrets" = prog;
                        apps.${system}."${name}-install-secrets" = {
                            type = "app";
                            program = lib.getExe prog;
                        };
                    };
            in utils.mergeAll (lib.mapAttrsToList build infra.secrets.installers);
               


        compileVisualization = 
            args:
                let conf = compileConfig args;
                    script =(import tools/visualization/main.nix 
                                {inherit inputs lib pkgs;
                                 inherit (conf) infra registry;}).main;
                in {
                    packages.${system}.visualization = script;
                    apps.${system}.visualization = {
                        description = "Visualize your infrastructure using graphviz";
                        type = "app";
                        program = lib.getExe script;
                    };
                };
 
                            

    

        
        compileTerranix = 
            args:
                let conf = compileConfig args;
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
                let conf = compileConfig args;
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


    in utils.mergeAll [
        (compileGenSecrets args) 
        (compileInstallSecrets args)
        (compileVisualization args)
        {
          

          lib = {
            inherit compileInfra compileRegistry compileTerranix compileGenSecrets compileNixos compileIso;
            inherit gen-config-checks;
          };


          infra = compileInfra args;
          #registry = compileRegistry args;
          #infra = gen-infra args;
          #registry = gen-registry args;
          terranix = compileTerranix args;
          #nixosConfigurations = compileNixos args // {iso = compileIso args;};

          #checks.${system} = gen-config-checks inputs;

          packages.${system}.options-doc = 
            let module = compileModule args;
            in (pkgs.nixosOptionsDoc {options = module.options;}).optionsJSON;
                       

          nixosConfigurations = nixos-generator args;
          #terranixConfigurations = terranix.lib.terranixConfiguration (terranix-generator ./example.nix);

    #        terranix.lib.terranixConfiguration {inherit system; 
    #                                            modules = [{config = (terranix-generator infra-config.infra);}];};
    #
      }

      ];

}

