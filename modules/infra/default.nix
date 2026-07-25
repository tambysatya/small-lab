{lib, config,...}:

{
  imports = [./infra.nix];

  
  config.assertions = lib.mapAttrsToList
    (vmName: vm: {
      assertion = builtins.hasAttr vm.host config.infra.hosts;
      message = "Undefined ${vm.host} for ${vmName}";
    }) config.infra.vms;

}
