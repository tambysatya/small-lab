
{inputs, infra, config, lib, pkgs, ... }:

let
  vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit lib infra inputs;};
  cfg = config.services.step-renew;
  installCert = name: cert:
    ''
        if [[ ! -d ${vars.ssl_basedir name} ]]; then
            echo "Installing certificate ${name}"
            install -o ${cert.owner} -m 0700 \
                ${vars.ssl_basedir name}
            install -o ${cert.owner} -m 0600 \
                /run/secrets/${name}.crt \
                ${vars.ssl_crt_path name}
            install -o ${cert.owner} -m 0600 \
                /run/secrets/${name}.key \
                ${vars.ssl_key_path name}
        fi
    '';
in
{
  config = lib.mkIf cfg.enable {

    systemd.services.step-bootstrap = {

      description = "Bootstrap Step CA";

      wantedBy = [ "multi-user.target" ];

      before = [ "step-renew.service" ];
      #depends on step-ca if installed locally
      after = ["network-online.target"] ++ lib.optional config.services.step-ca.enable "step-ca.service";
      requires = ["network-online.target"] ++ lib.optional config.services.step-ca.enable "step-ca.service";

      serviceConfig = {
        Type = "oneshot";
        StateDirectory = "step";
        Restart = "on-failure";
        RestartSec = "30s";
      };

      environment = {
        STEPPATH = cfg.stepPath;
      };

      script = ''
        set -euo pipefail

        if [ ! -f "$STEPPATH/config/defaults.json" ]; then
          echo "Bootstrapping Step"

          until ${pkgs.step-cli}/bin/step ca bootstrap \
		    --ca-url ${lib.escapeShellArg cfg.caURL} \
		    --fingerprint ${lib.escapeShellArg cfg.caFingerprint}
          do
            echo "Remote CA not available, retrying in 30s"
            sleep 30
          done
          chmod go+rx ${cfg.stepPath}/certs
          chmod go+r ${cfg.stepPath}/certs/root_ca.crt

          install -d -m 0601 ${cfg.stepPath}/ssl
          ${lib.concatStringsSep "\n"
                (lib.mapAttrsToList installCert cfg.certs)}
        fi
      '';

    };

  };
}
