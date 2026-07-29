{inputs, config, lib, pkgs, ...}:

/* Reads product_serial to identify which flakes to be deployed */


let installer = pkgs.writeShellApplication {
			name = "autoinstall";
			runtimeInputs = with pkgs; [
						git nix util-linux nixos-install-tools
						inputs.disko.packages.${pkgs.system}.disko
						curl
					];
			text = ''
				#!${pkgs.bash}/bin/bash
				set -euo pipefail


				HOST=$(cat /sys/class/dmi/id/product_serial)
				TOKEN=$(cat /sys/class/dmi/id/chassis_serial)
				echo "Deploying $HOST configuration"

				echo "Partitioning...."

				set -x
				
				printf 'yes\n' | disko --mode destroy  --flake "/etc/nixos#$HOST"
				disko --mode destroy,format,mount --yes-wipe-all-disks --flake "/etc/nixos#$HOST"
				set +x

				echo "Downloading the age key"
				set -x
				umask 077
				mkdir -p /var/lib/sops-nix
				mkdir -p /mnt/var/lib/sops-nix
				curl --cacert /etc/nixos/secrets/plain/CA/certs/intermediate_ca.crt "https://vm-provisioning.local.lphi.umontpellier.fr:8080/$HOST$TOKEN" > /var/lib/sops-nix/key.txt
				cp /var/lib/sops-nix/key.txt /mnt/var/lib/sops-nix
				set +x

				mkdir -p /mnt/var/lib/step-ca/certs/
				chmod 0755 /mnt/var/lib/step-ca/
				chmod 0755 /mnt/var/lib/step-ca/certs

				echo "Installing $HOST..."
				${config.system.build.nixos-install}/bin/nixos-install --flake "/etc/nixos#$HOST"

				
				systemctl --no-block reboot
				'';
		};
in {
	systemd.services.autoinstall = {
		wantedBy = ["multi-user.target"];
		after = ["network-online.target"];
		wants = ["network-online.target"];
		serviceConfig = {
			User = "root";
			Type = "oneshot";
			ExecStart = "${installer}/bin/autoinstall";
		};
	};
}
