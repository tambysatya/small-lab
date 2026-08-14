{lib,pkgs, config, inputs, infra, ...}:

let
    vars = import "${inputs.self.outPath}/lib/vars.nix" {inherit inputs lib infra;};
    bootstrapNode = ''
                    set -euo pipefail

                    if [ ! -f "/var/lib/garage/bootstrap-done" ]; then
                        echo "Bootstrap garage"

                            NODEID=`${pkgs.garage_2}/bin/garage node id`
                            SHORT_NODEID=''${NODEID:0:16}
                        if ! ${pkgs.garage_2}/bin/garage layout show | grep -q $SHORT_NODEID; then
                            ${pkgs.garage_2}/bin/garage layout assign -z dc1 -c 1G $NODEID
                                ${pkgs.garage_2}/bin/garage layout apply --version 1
                        else
                            echo "Skipping layout creation"
                        fi
                        touch /var/lib/garage/bootstrap-done
                    fi
    '';

    generateAccess = servicename: access@{bucket, keyID, ...}:
                    ''
                if [ ! -f "/var/lib/garage/bootstrap-${keyID}" ]; then
                        if ! ${pkgs.garage_2}/bin/garage bucket info ${bucket}; then
                            echo "Creating bucket: ${bucket}"
                            ${pkgs.garage_2}/bin/garage bucket create ${bucket}
                        else
                            echo "Skipping bucket creation: ${bucket}"
                        fi
                        if ! ${pkgs.garage_2}/bin/garage key info ${servicename}; then
                            echo "Creating nextcloud key"
                                ${pkgs.garage_2}/bin/garage key import --yes \
                                $(cat  ${config.sops.secrets."${vars.s3_id access}".path}) \
                                $(cat  ${config.sops.secrets."${vars.s3_key access}".path}) \
                                -n ${servicename}
                                ${pkgs.garage_2}/bin/garage bucket allow \
                                --read \
                                --write \
                                --owner \
                                ${bucket}\
                                --key ${servicename}
                        else
                            echo "Skipping creation ${servicename}:${keyID} [key already exists]"
                        fi

                touch /var/lib/garage/bootstrap-${keyID}
                fi
                    '';


        
        
in {
    inherit bootstrapNode generateAccess;
}
