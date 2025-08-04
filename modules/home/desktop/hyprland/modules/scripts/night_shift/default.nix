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
  cfg = config.${namespace}.desktop.hyprland.modules.scripts.night_shift;

  night-shift-on = pkgs.writeShellScriptBin "night-shift-on" ''
    ${pkgs.hyprshade}/bin/hyprshade on blue-light-filter
    title="󰖔  Night-Shift Activated"
    description="Night-Shift is now activated! Your screen will be warmer and easier on the eyes."

    notif "night-shift" "$title" "$description"
  '';

  night-shift-off = pkgs.writeShellScriptBin "night-shift-off" ''
    ${pkgs.hyprshade}/bin/hyprshade off
    title="󰖕  Night-Shift Deactivated"
    description="Night-Shift is now deactivated! Your screen will return to normal."

    notif "night-shift" "$title" "$description"
  '';

  night-shift = pkgs.writeShellScriptBin "night-shift" ''
    if [[ $(${pkgs.hyprshade}/bin/hyprshade current) ]]; then
      night-shift-off
    else
      night-shift-on
    fi
  '';

  night-shift-status = pkgs.writeShellScriptBin "night-shift-status" ''
    if [[ $(${pkgs.hyprshade}/bin/hyprshade current) ]]; then
      echo "1"
    else
      echo "0"
    fi
  '';

  night-shift-status-icon = pkgs.writeShellScriptBin "night-shift-status-icon" ''
    if [[ $(hyprshade current) ]]; then
        echo "󰖔"
      else
        echo "󰖕"
      fi
  '';
in
{
  options.${namespace}.desktop.hyprland.modules.scripts.night_shift = with types; {
    enable = mkBoolOpt false "Enable night shift control scripts";
  };

  config = mkIf cfg.enable {
    home.packages = [
      night-shift-on
      night-shift-off
      night-shift
      night-shift-status
      night-shift-status-icon
    ];
  };
}
