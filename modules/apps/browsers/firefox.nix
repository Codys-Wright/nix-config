# Firefox Browser aspect
{
  fleet,
  ...
}:
{
  fleet.apps._.browsers._.firefox = {
    description = "Firefox Browser - Mozilla's open-source browser";

    homeManager =
      { config, ... }:
      {
        # Install through programs.firefox, not home.packages: firefox_webapps
        # also enables programs.firefox, and HM's wrapped package differs from
        # pkgs.firefox, so both together collide in home-manager-path.
        programs.firefox.enable = true;
        programs.firefox.configPath = "${config.xdg.configHome}/mozilla/firefox";
      };
  };
}
