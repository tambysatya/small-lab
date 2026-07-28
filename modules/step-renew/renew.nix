
{ config, lib, pkgs, ... }:

let

  cfg = config.services.step-renew;

  certEntries =
    lib.mapAttrsToList
      (name: cert: ''
        echo "Renewing ${name}"

        old_hash=$(${pkgs.coreutils}/bin/sha256sum ${cert.cert} | cut -d' ' -f1)

        ${pkgs.step-cli}/bin/step ca renew \
          ${cert.cert} \
          ${cert.key} \
          --force

        new_hash=$(${pkgs.coreutils}/bin/sha256sum ${cert.cert} | cut -d' ' -f1)

        if [ "$old_hash" != "$new_hash" ]; then
          echo "${name} changed"

          ${lib.concatMapStringsSep "\n"
            (service:
              "${pkgs.systemd}/bin/systemctl reload-or-restart ${service}"
            )
            cert.reload}
        fi
      '')
      cfg.certs;

in
{

  config = lib.mkIf cfg.enable {

    environment.systemPackages = [pkgs.step-cli];
    systemd.services.step-renew = {

      description = "Renew Step certificates";

      # depends of step-ca if the service is installed locally
      after = [ "step-bootstrap.service" ] 
	      ++ lib.optional config.services.step-ca.enable "step-ca.service";
      requires = [ "step-bootstrap.service" ]
	      ++ lib.optional config.services.step-ca.enable "step-ca.service";

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

        ${lib.concatStringsSep "\n" certEntries}
      '';

    };

    systemd.timers.step-renew = {

      wantedBy = [ "timers.target" ];

      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };

    };

  };

}
