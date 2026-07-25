{lib,inputs,  ...}:
let

  utils = import ./utils.nix {inherit lib;};
  generateSopsSecret = 
    secretName: secret:
      {
        sops.secret."${secretName}" = {
          sopsFile = "${inputs.self.outPath}/secrets/encrypted/${secretName}.key";
          path = secret.path;
          format = "binary";
          owner = secret.owner;
          restartUnits = secret.restartUnits;
          mode = secret.mode;
        };
      };

in 
{
  generateSopsSecrets = secrets:  utils.mergeAll (lib.mapAttrsToList generateSopsSecret secrets);
}
