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

      terranix-generator_fun = (import ./lib/generators/terranix {inherit lib inputs;}).generator;
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
                                            ./modules/disko-vm.nix
                                            ./profiles/vm.nix

                                            ./modules/registry
                                            ./modules/registry/lib/processing

                                            ./modules/step-renew
                                            ./modules/step-ca
                                            ./modules/openldap
                                            ./modules/keycloak
                                            ./modules/garage
                                            ./modules/postgres
                                            ./modules/nextcloud

                                        ];
                                })
                            infra.vms;

        in configs;
        test-infra = compile-infra {
                        inventory = ./examples/example.nix;
                        extraArgs = {path=inputs.self.outPath;};
                     };
        test-registry = compile-registry test-infra;
    

            

        

    in {
      generators = {
        terranix = terranix-generator; 
        nixos = nixos-generator;
        infra = compile-infra;
        registry = compile-registry;
      };

      infra = test-infra;
      registry = test-registry;
                   

      #nixosConfigurations = configs;
      #terranixConfigurations = terranix.lib.terranixConfiguration (terranix-generator ./example.nix);

#        terranix.lib.terranixConfiguration {inherit system; 
#                                            modules = [{config = (terranix-generator infra-config.infra);}];};
#
  };


}

