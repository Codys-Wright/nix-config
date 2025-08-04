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
  cfg = config.${namespace}.desktop.hyprland.modules.hyprpaper;
in
{
  options.${namespace}.desktop.hyprland.modules.hyprpaper = with types; {
    enable = mkBoolOpt false "Enable Hyprland wallpaper daemon";
  };

  config = mkIf cfg.enable {
    services.hyprpaper = {
      enable = true;
      settings = {
        ipc = "on";
        splash = false;
        splash_offset = 2.0;
      };
    };
  };
}
