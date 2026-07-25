{lib, config, inputs, ...}:

/* Overlay of the SOPS secrets management tool */

let 
    generateSecret = 
      vmName: secretName: secret:
        generateOwnedSecret vmName secret.owner secretName secret
  ;
    generateOwnedSecret  = 
      vmName: owner: secretName: secret:
        let secretFile = "${inputs.self.outPath}/secrets/encrypted/${vmName}-${secretName}.enc";
        in {
            sops.secrets."${secretName}" = {
              sopsFile = secretFile;
              path = secret.path;
              format = "binary";
              owner = owner;
              restartUnits = secret.restartUnits;
              mode = secret.mode;
            };
        }

in {

  generateSecrets = vmName: secrets: lib.mkMerge (lib.mapAttrsToList (generateSecret vmName) secrets);
  generateOwnedSecrets = vmName: owner: secrets: lib.mkMerge (lib.mapAttrsToList (generateOwnedSecret vmName owner) secrets);

}
