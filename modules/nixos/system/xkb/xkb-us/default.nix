{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.xkb.xkb-us;
in
{
  options.${namespace}.system.xkb.xkb-us = {
    enable = mkBoolOpt false "${namespace}.config.xkb.xkb-us.enable";
  };

  config = mkIf cfg.enable {
    services.xserver.xkb = {
      layout = "us";
      variant = "altgr-intl";
    };
  };
}
