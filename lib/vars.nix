/* Standard definitions of names, paths... */

{lib, infra, registry, inputs,...}:

let
    path = infra.secretsPath;
    age = lib.escapeShellArg "${lib.escapeShellArg infra.secretsPath}/age";
    plain = "${lib.escapeShellArg infra.secretsPath}/plain";
    git = "${lib.escapeShellArg infra.secretsPath}/git"; #everything that can be versionned
    enc = "${git}/enc";

in {
    inherit path age plain git enc;
}
