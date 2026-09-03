{inputs, config, lib, pkgs, infra, ...}:

/* Reads product_serial to identify which flakes to be deployed */


let vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit lib infra inputs;};
    installer = pkgs.writeShellApplication {
			name = "autoinstall";
			runtimeInputs = with pkgs; [
						git nix util-linux nixos-install-tools
						inputs.disko.packages.${pkgs.system}.disko
						curl gzip
					];
			text = ''
				#!${pkgs.bash}/bin/bash
				set -euo pipefail


				HOST=$(cat /sys/class/dmi/id/product_serial)
				TOKEN=$(cat /sys/class/dmi/id/chassis_serial)
				echo "Deploying $HOST configuration"

				echo "Partitioning...."

				set -x
				
				#printf 'yes\n' | disko --mode destroy  --flake "/etc/nixos#$HOST"
				disko --mode format,mount --yes-wipe-all-disks --flake "/etc/nixos#$HOST"
				#disko --mode destroy,format,mount --yes-wipe-all-disks --flake "/etc/nixos#$HOST"
				set +x

				echo "Downloading the secrets"
				set -x
				curl --cacert /etc/nixos/${vars.git}/intermediate_ca.crt "https://vm-provisioning.local.lphi.umontpellier.fr:8080/$TOKEN.tar.gz" > /tmp/
                cd /tmp/
                tar -xvf ${TOKEN}.tar.gz
                cd $HOST
                installer="$(nix eval --raw /etc/nixos#infra.secrets.installer.$HOST)"
                

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
