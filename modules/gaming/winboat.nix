# Winboat - run Windows apps on Linux with seamless integration
{
  fleet,
  ...
}:
{
  fleet.gaming._.winboat = {
    description = "Winboat - run Windows apps on Linux with seamless integration";

    homeManager =
      { pkgs, lib, ... }:
      lib.mkIf (!pkgs.stdenv.isDarwin) {
        home.packages = [ pkgs.winboat ];
      };
  };
}
