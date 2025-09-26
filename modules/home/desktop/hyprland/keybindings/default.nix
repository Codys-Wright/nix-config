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
  cfg = config.${namespace}.desktop.hyprland.keybindings;
in
{
  options.${namespace}.desktop.hyprland.keybindings = with types; {
    enable = mkBoolOpt false "Enable hyprland keybindings";
  };
  config = mkIf cfg.enable {
    wayland.windowManager.hyprland.settings = {
      bind =
        [
          "$mod,RETURN, exec, ${pkgs.kitty}/bin/kitty" # Kitty
          "$mod,E, exec, ${pkgs.nautilus}/bin/nautilus" # Nautilus
          "$mod,B, exec, ${pkgs.librewolf}/bin/librewolf" # Librewolf
          "$mod,K, exec, ${pkgs.bitwarden}/bin/bitwarden" # Bitwarden
          "$mod,L, exec, ${pkgs.hyprlock}/bin/hyprlock" # Lock
          "$mod,X, exec, power-menu" # Powermenu
          "$mod,SPACE, exec, caelestia shell drawers toggle launcher " # Launcher
          "$shiftMod,SPACE, exec, hyprfocus-toggle" # Toggle HyprFocus

          "$mod,Q, killactive," # Close window
          "$mod,T, togglefloating," # Toggle Floating
          "$mod,F, fullscreen" # Toggle Fullscreen
          "$mod,left, movefocus, l" # Move focus left
          "$mod,right, movefocus, r" # Move focus Right
          "$mod,up, movefocus, u" # Move focus Up
          "$mod,down, movefocus, d" # Move focus Down
          "$shiftMod,up, focusmonitor, -1" # Focus previous monitor
          "$shiftMod,down, focusmonitor, 1" # Focus next monitor
          "$shiftMod,left, layoutmsg, addmaster" # Add to master
          "$shiftMod,right, layoutmsg, removemaster" # Remove from master

          "$mod,PRINT, exec, screenshot window" # Screenshot window
          ",PRINT, exec, screenshot monitor" # Screenshot monitor
          "$shiftMod,PRINT, exec, screenshot region" # Screenshot region
          "ALT,PRINT, exec, screenshot region swappy" # Screenshot region then edit

          "$shiftMod,S, exec, ${pkgs.librewolf}/bin/librewolf :open $(rofi --show dmenu -L 1 -p ' Search on internet')" # Search on internet with rofi
          "$shiftMod,C, exec, clipboard" # Clipboard picker with rofi
          "$mod,F2, exec, night-shift" # Toggle night shift
        ]
        ++ (builtins.concatLists (
          builtins.genList (
            i:
            let
              ws = i + 1;
            in
            [
              "$mod,code:1${toString i}, workspace, ${toString ws}"
              "$mod SHIFT,code:1${toString i}, movetoworkspace, ${toString ws}"
            ]
          ) 9
        ));

      bindm = [
        "$mod,mouse:272, movewindow" # Move Window (mouse)
        "$mod,R, resizewindow" # Resize Window (mouse)
      ];

      bindl = [
        ",XF86AudioMute, exec, sound-toggle" # Toggle Mute
        ",switch:on:Lid Switch, exec, hyprctl keyword monitor 'eDP-1, disable'"
        ",switch:off:Lid Switch, exec, hyprctl keyword monitor 'eDP-1, prefered, auto, auto'"
      ];

      bindle = [
        ",XF86AudioRaiseVolume, exec, sound-up" # Sound Up
        ",XF86AudioLowerVolume, exec, sound-down" # Sound Down
        ",XF86MonBrightnessUp, exec, brightness-up" # Brightness Up
        ",XF86MonBrightnessDown, exec, brightness-down" # Brightness Down
      ];
    };
  };
}
