{lib, inputs, ...}:

let generators = {
      step-ca = 
        infra: vmName: 
          (import ./step-ca.nix {inherit lib inputs;}).generator infra vmName;
       openldap = 
        infra: vmName:
          (import ./openldap.nix {inherit lib inputs;}).generator infra vmName;
    };

in {
  inherit generators; 
  generator = infra: vmName: serviceName:
      generators."${serviceName}" infra vmName;
}
