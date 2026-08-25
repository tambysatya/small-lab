{lib,...}:

let 
    types = lib.types;
in

rec {
    /* Basic types constructors */
    filename = lib.mkOption {
        description = "Name of the file";
        type = types.str;
    };

    owner = lib.mkOption {
        description = "Username of the owner";
        type = types.str;
        default = "root";
    };
    reload = lib.mkOption {
        description = "Services to be reloaded";
        type = types.listOf types.str;
        default = [];
    };
    dirmode = lib.mkOption {
        description = "Permissions of the directory";
        type = types.str;
        default = "0700";
    };
    filemode = lib.mkOption {
        description = "Permissions of the file";
        type = types.str;
        default = "0400";
    };

}
