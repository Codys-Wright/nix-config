# Brave Browser aspect
{
  fleet.apps._.communications._.discord = {
    description = "Discord";

    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      {
        home.packages = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.equibop ];
      };
  };
}
