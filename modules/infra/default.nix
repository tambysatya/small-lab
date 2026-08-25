{lib, inputs, config,...}:

let
    infratypes= import "${inputs.self.outPath}/lib/types" {inherit inputs lib;};
    types = infratypes;

    serviceModules = map (name: "${inputs.self.outPath}/services/${name}/register.nix") types.serviceNames;

in {
  imports = [./topology
             ./services
             ./secrets
             ./vms] ++ serviceModules;

/*  
  config.assertions = lib.mapAttrsToList
    (vmName: vm: {
      assertion = builtins.hasAttr vm.host config.infra.hosts;
      message = "Undefined ${vm.host} for ${vmName}";
    }) config.infra.vms;
*/
}
