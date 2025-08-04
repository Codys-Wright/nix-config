{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.hyprland.modules.scripts;
in
{
  options.${namespace}.desktop.hyprland.modules.scripts = with types; {
    enable = mkBoolOpt false "Enable Hyprland utility scripts";
  };

  config = mkIf cfg.enable {
    ${namespace}.desktop.hyprland.modules.scripts = {
      brightness = enabled;
      caffeine = enabled;
      hyprfocus = enabled;
      hyprpanel = enabled;
      night_shift = enabled;
      notification = enabled;
      screenshot = enabled;
      sounds = enabled;
      system = enabled;
    };
  };
}
