{inputs, lib, infra, pkgs, ...}:

let

    gen = import ./lib {inherit inputs lib pkgs infra;};

    generateNodes =
        lib.concatStringsSep "\n" (lib.mapAttrsToList gen.generateServiceNodes infra.services);
    generateEdges =
        lib.concatStringsSep "\n" (lib.mapAttrsToList gen.generateServiceEdges infra.services);

    code = pkgs.writeText ".graph.dot"
           ''
            digraph infra {
                rankdir = "LR";
                ${generateNodes}
                ${generateEdges}
            }
           '';

in
{
    main = pkgs.writeShellApplication {
            name = "visualization";
            runtimeInputs = [
                pkgs.graphviz
            ];
            #dummy
            text = ''
                ${pkgs.graphviz}/bin/dot -Tsvg ${code} -o infra.svg
            '';
           };
}
