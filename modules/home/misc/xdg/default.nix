{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.misc.xdg;
in
{
  options.${namespace}.misc.xdg = {
    enable = mkBoolOpt false "${namespace}.misc.xdg.enable";
  };

  config = mkIf cfg.enable { xdg = enabled; };
}
