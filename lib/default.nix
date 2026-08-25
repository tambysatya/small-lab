{lib, inputs, ...}:

let 
    types = lib.types // (import "${inputs.self.outPath}/lib/types" {inherit lib inputs;});

    ageKeyFromDeployementEnvironment = 
        env@{type, host, priority, ...}:
            if type == "vm"
                then "${host}"
            else if type == "container"
                then "${host.vm}-${host.container}"
            else
                throw "Unknown deployement environment ${env}";
    merge = a: b:
      if lib.isList a && lib.isList b then
        a ++ b
      else if lib.isAttrs a && lib.isAttrs b then #browses a, check if each value is present in b and merge them
        lib.mapAttrs (name: value:
          if builtins.hasAttr name b then
            merge value b.${name}
          else
            value
        )
        a 
        // (builtins.removeAttrs b (builtins.attrNames a)) # we concat to b since the fields shared by a and b are now in the term.
      else 
        b;
    pathToMountUnit = path:
      if path == "/" then
        "-.mount"
      else
        "${(lib.replaceStrings [ "/" ] [ "-" ] (lib.removePrefix "/" path))}.mount";

    mergeAll = listOfAttrsets: lib.foldl' merge {} listOfAttrsets;

in{
    inherit ageKeyFromDeployementEnvironment mergeAll pathToMountUnit;
}
