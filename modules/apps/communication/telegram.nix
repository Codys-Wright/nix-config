# Telegram Desktop
{
  fleet,
  ...
}:
{
  fleet.apps._.communications._.telegram = {
    description = "Telegram Desktop messenger";

    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      {
        home.packages = lib.mkIf (!pkgs.stdenv.hostPlatform.isDarwin) [ pkgs.telegram-desktop ];
      };
  };
}
