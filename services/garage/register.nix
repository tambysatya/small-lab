{lib, inputs, config, pkgs, ...}:

let 
    infra = config.infra;
    reg = import "${inputs.self.outPath}/lib/registry/register.nix" {inherit inputs lib infra;};
    secret = {
        names = ["garage-rpc.key" "garage-admin.key" "garage-metrics.key"];
        owner = "garage";
        reload = ["garage.service"];
        kind = {
            provider = "openssl";
            providerArgs = {
                size = 32;
                type = "hex";
            };
        };
    };
    endpoints = [
        {
            host = "s3.${infra.domain}";
            port = 3900;
             extraNginxConfig = {
                virtualHosts."s3.${infra.domain}".extraConfig = 
                    ''
                        proxy_request_buffering off;
                        proxy_buffering off;
                        proxy_http_version 1.1;
                        proxy_read_timeout 1h;
                        proxy_send_timeout 1h;
                        send_timeout 3600s;
                        client_body_timeout 3600s;

                        proxy_set_header Host $host;
                        proxy_set_header X-Real-IP $remote_addr;
                        proxy_set_header Connection "";
                        proxy_set_header Transfer-Encoding "";

                        keepalive_timeout 65s;

                    '';
                clientMaxBodySize = "100G";
             };

        }
        {
            host = "s3-admin.${infra.domain}";
            port = 3903;
        }
    ];

in {
    config.registry = 
                lib.mkMerge [
                    (reg.registerSecret "garage" "garage-keys" secret)
                    (reg.registerEndpoints "garage" endpoints)
                    (reg.registerUser "garage" "garage" 10001)
                ];
}


