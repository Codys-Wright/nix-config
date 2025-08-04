{
  options,
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.desktop.hyprland.modules.hyprpanel;

  transparentButtons = false;
  accent = "#${config.lib.stylix.colors.base0D}";
  accent-alt = "#${config.lib.stylix.colors.base03}";
  background = "#${config.lib.stylix.colors.base00}";
  background-alt = "#${config.lib.stylix.colors.base01}";
  foreground = "#${config.lib.stylix.colors.base05}";
  font = "${config.stylix.fonts.serif.name}";
  fontSize = "${toString config.stylix.fonts.sizes.desktop}";

  rounding = 10;
  border-size = 1;
  gaps-out = 5;
  gaps-in = 3;
  floating = true;
  transparent = true;
  position = "top";

  location = "Zurich";
  username = "ryan";
in
{
  options.${namespace}.desktop.hyprland.modules.hyprpanel = with types; {
    enable = mkBoolOpt false "Enable HyprPanel desktop panel";
  };

  #  imports = [ inputs.hyprpanel.homeManagerModules.hyprpanel ];

  config = mkIf cfg.enable {
    programs.hyprpanel = {
      enable = true;
      systemd.enable = true;
      # hyprland.enable = true;
      # overwrite.enable = true;
      # overlay.enable = true;
      settings = {
        layout = {
          "bar.layouts" = {
            "0" = {
              "left" = [
                "dashboard"
                "workspaces"
                "windowtitle"
              ];
              "middle" = [ "media" ];
              "right" = [
                "systray"
                "volume"
                "bluetooth"
                # "battery"
                "network"
                "clock"
                "notifications"
              ];
            };
          };
        };
      };
    };
  };
}
