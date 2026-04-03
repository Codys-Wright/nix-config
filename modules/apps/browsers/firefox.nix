# Firefox Browser aspect
{
  FTS,
  ...
}:
{
  FTS.apps._.browsers._.firefox = {
    description = "Firefox Browser - Mozilla's open-source browser";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.firefox ];
      };
  };
}
