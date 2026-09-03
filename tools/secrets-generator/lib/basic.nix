{lib, inputs, pkgs,...}:
let
    utils = import "${inputs.self.outPath}/lib" {inherit lib inputs;};
    generateIdentity = 
        env:
        if env.type == "vm" then ''
            mkdir -p ".secrets/perVM/${utils.envUID env}"
        ''
        else ''
            mkdir -p ".secrets/perVM/${env.host.vm}/${env.host.container}"
        '';
    give = filename: env: 
        let filepath = ".secrets/plain/${filename}";
            target = if env.type == "vm"
                     then ".secrets/perVM/${env.host}/${filename}"
                     else ".secrets/perVM/${env.host.vm}/${env.host.container}/${filename}";
        in ''cp ${filepath} ${target}'';

    ship = 
        name:
        let 
            path = ".secrets/perVM";
            provisioner = ".secrets/provisioner";
            tokens = ".secrets/tokens";
        in ''
            mkdir -p ${provisioner}
            mkdir -p ${tokens}
            tar -cvf ${path}/${name}.tar ${path}/*
            ${lib.getExe pkgs.gzip} ${path}/${name}.tar

            TOKEN=$(${lib.getExe pkgs.openssl} rand -hex 64)
            mv ${path}/${name}.tar.gz "${provisioner}/$TOKEN.tar.gz"
            echo "$TOKEN" > "${tokens}/${name}.token"
        '';
        

in
{
    inherit give generateIdentity ship;
}
