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
      darwin = { ... }: {
        nix.settings = {
          trusted-users = [ "root" "@admin" "CodyWright" ];
          substituters = [
            "https://cache.nixos.org/"
            "https://devenv.cachix.org"
            "https://fasttrackstudio.cachix.org"
          ];
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
            "fasttrackstudio.cachix.org-1:r7v7WXBeSZ7m5meL6w0wttnvsOltRvTpXeVNItcy9f4="
          ];
        };
      };
    };
  };

}
