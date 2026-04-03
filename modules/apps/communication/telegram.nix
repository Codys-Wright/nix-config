# Telegram Desktop
{
  FTS,
  ...
}:
{
  FTS.apps._.communications._.telegram = {
    description = "Telegram Desktop messenger";

    homeManager =
      {
        pkgs,
        lib,
        ...
      }:
      {
        home.packages = lib.mkIf (!pkgs.stdenv.isDarwin) [ pkgs.telegram-desktop ];
      };
  };
}
