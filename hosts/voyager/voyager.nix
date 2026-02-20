{ inputs, FTS, __findFile, ... }:

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

  den.aspects = {
    voyager = {
      includes = [
        <FTS/fonts>
        <FTS/phoenix>
      ];
    };
  };

}