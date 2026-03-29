{
  inputs,
  FTS,
  __findFile,
  ...
}:

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
      darwin =
        { pkgs, ... }:
        {
          environment.systemPackages = [
            pkgs.tailwindcss_4
            pkgs.cachix
          ];
          nix.settings = {
            cores = 10;
            max-jobs = 3;
            trusted-users = [
              "root"
              "@admin"
              "CodyWright"
            ];
          };
        };
    };
  };

}
