# Brave Browser aspect
{
  fleet.apps._.misc._.localsend = {
    description = "Brave Browser - Privacy-focused Chromium-based browser";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.localsend ];
      };
  };
}
