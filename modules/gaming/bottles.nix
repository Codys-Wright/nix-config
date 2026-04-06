# Bottles - Windows app runner using Wine
{
  fleet,
  ...
}:
{
  fleet.gaming._.bottles = {
    description = "Bottles - run Windows applications and games with Wine";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf (!pkgs.stdenv.isDarwin) {
        home.packages = [ pkgs.bottles ];
      };
  };
}
