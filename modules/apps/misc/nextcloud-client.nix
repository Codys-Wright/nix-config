# Brave Browser aspect
{
  FTS,
  ...
}:
{
  FTS.apps._.misc._.nextcloud-client = {
    description = "Brave Browser - Privacy-focused Chromium-based browser";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.nextcloud-client ];
      };

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.nextcloud-client ];
      };
  };
}
