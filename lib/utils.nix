{lib,...}:

  /* Merges two attrsets recursively (concatenates submodules, lists,...) */
rec{
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

    mergeAll = listOfAttrsets: lib.foldl' merge {} listOfAttrsets;
}
