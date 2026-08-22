{lib, inputs, ...}:

let 
    types = lib.types // (import "${inputs.self.outPath}/lib/types" {inherit lib inputs;});

    ageKeyFromDeployementEnvironment = 
        env@{type, host, priority, ...}:
            if type == "vm"
                then "${host}-${lib.toString priority}.key"
            else if type == "container"
                then "${host.vm}-${host.container}-${lib.toString priority}.key"
            else
                throw "Unknown deployement environment ${env}";
in{
    inherit ageKeyFromDeployementEnvironment;
}
