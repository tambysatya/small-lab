/* Standard definitions of names, paths... */

{lib, infra, registry, inputs,...}:

let
    path = infra.secretsPath;
    age = lib.escapeShellArg "${lib.escapeShellArg infra.secretsPath}/age";
    plain = "${lib.escapeShellArg infra.secretsPath}/plain";
    git = "${lib.escapeShellArg infra.secretsPath}/git"; #everything that can be versionned
    enc = "${git}/enc";

    get-ct-id = vmname: service: "ct-${vmname}-${service}"; #returns the containers ID
in {
    inherit path age plain git enc;
    inherit get-ct-id;
}
