# Firefox Browser aspect
{
  fleet,
  ...
}:
{
  fleet.apps._.browsers._.firefox = {
    description = "Firefox Browser - Mozilla's open-source browser";

    homeManager =
      { config, pkgs, ... }:
      {
        home.packages = [ pkgs.firefox ];
        programs.firefox.configPath = "${config.xdg.configHome}/mozilla/firefox";
      };
  };
}
