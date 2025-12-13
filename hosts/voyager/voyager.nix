{ inputs, ... }:

{

  den.hosts.aarch64-darwin = {
    voyager = {
      description = "Portable laptop to take into the field";
      users.cody = {
        userName = "CodyWright";
      };
      aspect = "voyager";
    };
  };

  # voyager host-specific aspect
  den.aspects = {
    voyager = {
      # No includes yet - add system-level config here when needed
      includes = [ ];
    };
  };

}