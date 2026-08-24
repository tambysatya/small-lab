{lib, inputs, ...}:

let 
    types = lib.types // (import "${inputs.self.outPath}/lib/types" {inherit lib inputs;});

    ageKeyFromDeployementEnvironment = 
        env@{type, host, priority, ...}:
            if type == "vm"
                then "${host}"
            else if type == "container"
                then "${host.vm}-${host.container}"
            else
                throw "Unknown deployement environment ${env}";
in{
    inherit ageKeyFromDeployementEnvironment;
}
