{lib, inputs, ...}:

let generators = {
      step-ca = 
        infra: vmName: vmConf: 
          (import ./step-ca.nix {inherit lib inputs;}).generator infra vmName;
    };

in {
  inherit generators; 
  generator = infra: vmName: vmConf: serviceName:
      generators."${serviceName}" infra vmName vmConf;
}
