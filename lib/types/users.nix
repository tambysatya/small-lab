{lib,inputs, ...}:
let 
    types = lib.types;
in
{

    user = types.submodule {
        options = {
            name = lib.mkOption {
                description = "Username. A group will be created with the same name";
                type = types.str;
            };
            uid = lib.mkOption {
                description = "Identifier of the user. A group will be created with the same ID";
                type = types.ints.positive;
            };
        };
    };

}
