# Firefox Browser aspect
{
  fleet,
  ...
}:
{
  fleet.apps._.browsers._.firefox = {
    description = "Firefox Browser - Mozilla's open-source browser";

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.firefox ];
      };
  };
}
