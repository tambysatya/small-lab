{lib, inputs, pkgs,...}:
let
    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};
    generateIdentity = 
        env:
        if env.type == "vm" then ''
            mkdir -p ".secrets/provisioner/${utils.envUID env}"
        ''
        else ''
            mkdir -p ".secrets/provisioner/${env.host.vm}/${env.host.container}"
        '';
    give = filename: env: 
        let filepath = ".secrets/plain/${filename}";
            target = if env.type == "vm"
                     then ".secrets/provisioner/${env.host}/${filename}"
                     else ".secrets/provisioner/${env.host.vm}/${env.host.container}/${filename}";
        in ''cp ${filepath} ${target}'';
        

in
{
    inherit give generateIdentity;
}
