/* Volumes processing: generation of systemd-mount services  and volumes initializations*/


{inputs, lib, pkgs, infra, registry, ...}:
let

    utils = import "${inputs.self.outPath}/lib/utils.nix" {inherit lib;};
    /* Mounts a directory in sourcedir into the where destination */
    generateSystemdBindMount = 
        sourcedir:
        mount@{what, where, owner, mode}:
        {
            systemd.mounts = [
                {
                    what = "${sourcedir}/${lib.removePrefix "/" what}";
                    where = mount.where;
                    options = "bind"; 
                    type = "none"; #no filesystem
                    after = ["init-${utils.pathToMountUnit sourcedir}.service"]; # initialization of the sourcedir (first creation of the directories)
                    requires = ["init-${utils.pathToMountUnit sourcedir}.service"];
                    wantedBy = ["multi-user.target"];
                }
            ];
        };
    # Initializes a sourcedirectory
    generateInitSourceDir =
        sourcedir:
        mounts: #list of directories to create
            let script = lib.concatMapStringsSep "\n"
                (mount@{what, where, owner, mode}:
                    let sourcepath = "${sourcedir}/${lib.removePrefix "/" what}"
                    in ''
                        if [[ ! -d ${sourcepath} ]]; then
                            mkdir -p ${sourcepath}
                            chown ${owner} ${sourcepath}
                            chmod ${mode} ${sourcepath}
                        fi
                    '')
                mounts;
            in {
                systemd.services."init-${utils.pathToMountUnit sourcedir}" = {
                    description = "Initialize the mountpoint ${sourcedir} with a list of directories";
                    after = ["${utils.pathToMountUnit sourcdir}.service"];
                    requires = ["${utils.pathToMountUnit sourcdir}.service"];
                    serviceConfig = {
                        Type = "oneshot";
                    };
                    inherit script;
                };
            };
in {
    inherit generateSystemdBindMount generateInitSourceDir;
}
