{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.locale;
in
{
  options.${namespace}.system.locale = {
    enable = mkBoolOpt false "${namespace}.config.locale.enable";
  };

  config = mkIf cfg.enable {
    i18n = {
      defaultLocale = "en_GB.UTF-8";

      extraLocaleSettings = {
        LC_ADDRESS = "de_CH.UTF-8";
        LC_IDENTIFICATION = "de_CH.UTF-8";
        LC_MEASUREMENT = "de_CH.UTF-8";
        LC_MONETARY = "de_CH.UTF-8";
        LC_NAME = "de_CH.UTF-8";
        LC_NUMERIC = "de_CH.UTF-8";
        LC_PAPER = "de_CH.UTF-8";
        LC_TELEPHONE = "de_CH.UTF-8";
        LC_TIME = "en_GB.UTF-8";
      };
    };
    time.timeZone = "Europe/Zurich";
  };
}
