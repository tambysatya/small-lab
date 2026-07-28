{lib, inputs, config, infra, vmname, vmconf, pkgs,...}:

let 
    reg = import ../registry/lib/register.nix {inherit inputs lib vmname infra;};
    secrets = {
		/* API keys */
		"nextcloud_s3_id.key" = {path = "/var/lib/garage/nextcloud_s3_id.key";};
		"nextcloud_s3.key" = {path = "/var/lib/garage/nextcloud_s3.key";};
		/* Admin secrets */
		"garage-rpc.key" = {path = "/var/lib/garage/garage-rpc.key";};
		"garage-admin.key" = {path = "/var/lib/garage/garage-admin.key";};
		"garage-metrics.key" = {path = "/var/lib/garage/garage-metrics.key";};
	};
    endpoints = [
        {
            host = "s3.${infra.domain}";
            port = 3900;
        }
        {
            host = "s3-admin.${infra.domain}";
            port = 3903;
        }
    ];

in {
    config = lib.mkIf (builtins.elem "garage" vmconf.services)
                (lib.mkMerge [
                    (reg.registerSecrets "garage" "garage" ["garage.service"] secrets)
                    (reg.registerEndpoints "garage" endpoints)]);
}


