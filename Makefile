


test:
	nix eval --impure path:.#debugModule.identity.config.sops.secrets --json  | jq -C
