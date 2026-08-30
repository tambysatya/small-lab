{lib, inputs, ...}:

let 
    types = lib.types // (import "${inputs.self.outPath}/lib/types" {inherit lib inputs;});

    vars = import ./vars.nix {inherit lib inputs;};

    # Retrieve the AGE Unique Identifier of a  component

    merge = path: a: b:
      if lib.isList a && lib.isList b then
        a ++ b
      else if lib.isAttrs a && lib.isAttrs b then #browses a, check if each value is present in b and merge them
        lib.mapAttrs (name: value:
          if builtins.hasAttr name b then
            merge "${path}.${name}" value b.${name}
          else
            value
        )
        a 
        // (builtins.removeAttrs b (builtins.attrNames a)) # we concat to b since the fields shared by a and b are now in the term.
      else if a == b then a
      else
        throw "Merge: clash during mergeAll: ${path}: ${builtins.toJSON a} and ${builtins.toJSON b}";
    pathToMountUnit = path:
      if path == "/" then
        "-.mount"
      else
        "${(lib.replaceStrings [ "/" ] [ "-" ] (lib.removePrefix "/" path))}.mount";

    mergeAll = listOfAttrsets: lib.foldl' (merge "") {} listOfAttrsets;

    serviceName = config: id:
        config.infra.topology.services.${id}.is;
    servicePriority = config: id:
        config.infra.topology.services.${id}.priority;
    serviceTags = config: id:
        config.infra.topology.services.${id}.tags;
    serviceInfo = config: id:
        let srvname = serviceName config id;
        in config.infra.services.${srvname};

in vars // {
    inherit mergeAll pathToMountUnit;
    inherit serviceName servicePriority serviceTags serviceInfo;
}
