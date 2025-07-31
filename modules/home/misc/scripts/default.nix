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
  cfg = config.${namespace}.misc.scripts;
in
{
  options.${namespace}.misc.scripts = with types; {
    enable = mkBoolOpt false "Enable misc.scripts";
  };

  config = mkIf cfg.enable {
    ${namespace}.misc.scripts = {
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
