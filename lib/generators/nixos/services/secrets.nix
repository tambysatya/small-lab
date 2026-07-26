{lib,  ...}:

/* Overlay of the SOPS secrets management tool */

let 
    generateSecret = 
      vmName: owner: reload: secretName: secret:
          {inputs,...}:
          let secretFile = "${inputs.self.outPath}/secrets/encrypted/${vmName}-${secretName}.enc";
          in {
            sops.secrets."${secretName}" = {
                sopsFile = secretFile;
                path = secret.path;
                format = "binary";
                owner = owner;
                restartUnits = reload;
                mode = secret.mode or "400";
             };
           };

in {

  
  # Generate the sops options for an attrset of secrets (same owner, same reloadUnit
  generateSecrets = vmName: owner: reload: secrets:
                        {
                          imports = lib.mapAttrsToList (generateSecret vmName owner reload) secrets;
                        };


}
