{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.system.xkb.xkb-ch;
in
{
  options.${namespace}.system.xkb.xkb-ch = {
    enable = mkBoolOpt false "${namespace}.config.xkb.xkb-ch.enable";
  };

  config = mkIf cfg.enable {
    services.xserver.xkb = {
      layout = "ch";
    };
  };
}
