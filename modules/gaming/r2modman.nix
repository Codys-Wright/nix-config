# r2modman mod manager aspect
{
  FTS,
  ...
}:
{
  FTS.apps._.gaming._.r2modman = {
    description = "r2modman mod manager for Thunderstore mods";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf (!pkgs.stdenv.isDarwin) {
        home.packages = [ pkgs.r2modman ];
      };

    nixos =
      { pkgs, lib, ... }:
      lib.mkIf (!pkgs.stdenv.isDarwin) {
        environment.systemPackages = [ pkgs.r2modman ];
      };
  };
}
