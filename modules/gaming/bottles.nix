# Bottles - Windows app runner using Wine
{
  FTS,
  ...
}:
{
  FTS.gaming._.bottles = {
    description = "Bottles - run Windows applications and games with Wine";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf (!pkgs.stdenv.isDarwin) {
        home.packages = [ pkgs.bottles ];
      };
  };
}
