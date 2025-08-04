{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.primatives.xdg;
in
{
  options.${namespace}.desktop.primatives.xdg = {
    enable = mkBoolOpt false "Enable XDG base directory specification";
  };

  config = mkIf cfg.enable { xdg = enabled; };
}
