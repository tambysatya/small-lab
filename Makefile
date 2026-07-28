


phase1:
	nix eval --impure path:.#debugPhase1 --json  | jq -C
	
test:
	nix eval --impure path:.#debugPhase2.identity.config.sops.secrets --json  | jq -C
