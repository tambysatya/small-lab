{inputs, lib, infra, ,...}:
/* Helpers to browse the registry */

let
    # Extract all the users involved with the service
    serviceUsers = registry: servicename: 
        let service = registry.services."${servicename}";
            getOwner = builtins.getAttr owner;
        in lib.lists.unique (
                bultins.concatLists (
                    (map getOwner service.secrets)
                    (map getOwner service.dbAccesses)
                    (map getOwner service.s3Accesses)
                    (map getOwner service.volumes));

in{
    inherit serviceUsers;
}

