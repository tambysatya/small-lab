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

    ship = 
        name:
        let 
            path = ".secrets/provisioner";
        in ''
            tar -cvf ${path}/${name}.tar ${path}/*
            ${lib.getExe pkgs.gzip} ${path}/${name}.tar

            TOKEN=$(${lib.getExe pkgs.openssl} rand -hex 64)
            mv ${path}/${name}.tar.gz "${path}/$TOKEN.tar.gz"
            echo "$TOKEN" > ".secrets/${name}.token"
        '';
        

in
{
    inherit give generateIdentity ship;
}
