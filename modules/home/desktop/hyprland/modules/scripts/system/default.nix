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
  cfg = config.${namespace}.desktop.hyprland.modules.scripts.system;

  menu =
    pkgs.writeShellScriptBin "menu"
      # bash
      ''
        if pgrep rofi; then
        	pkill rofi
        else
        	rofi --show drun
        fi
      '';

  powermenu =
    pkgs.writeShellScriptBin "powermenu"
      # bash
      ''
        if pgrep rofi; then
        	pkill rofi
        else
          options=(
            "󰌾 Lock"
            "󰍃 Logout"
            " Suspend"
            "󰑐 Reboot"
            "󰿅 Shutdown"
          )

          selected=$(printf '%s\n' "''${options[@]}" | rofi --dmenu)
          selected=''${selected:2}

          case $selected in
            "Lock")
              ${pkgs.hyprlock}/bin/hyprlock
              ;;
            "Logout")
              hyprctl dispatch exit
              ;;
            "Suspend")
              systemctl suspend
              ;;
            "Reboot")
              systemctl reboot
              ;;
            "Shutdown")
              systemctl poweroff
              ;;
          esac
        fi
      '';

  lock =
    pkgs.writeShellScriptBin "lock"
      # bash
      ''
        ${pkgs.hyprlock}/bin/hyprlock
      '';
in
{
  options.${namespace}.desktop.hyprland.modules.scripts.system = with types; {
    enable = mkBoolOpt false "Enable system control scripts";
  };

  config = mkIf cfg.enable {
    home.packages = [
      menu
      powermenu
      lock
    ];
  };
}
