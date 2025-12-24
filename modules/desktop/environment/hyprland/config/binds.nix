# Hyprland keybindings configuration
{
  FTS,
  pkgs,
  ...
}: {
  FTS.desktop._.environment._.hyprland._.config._.binds = {
    description = "Hyprland keybindings configuration";

    homeManager = {pkgs, ...}: {
      wayland.windowManager.hyprland.settings = {
        # Modifier key variable
        "$mod" = "SUPER";

        # Regular keybindings
        bind = [
          # Applications
          "$mod, RETURN, exec, ${pkgs.kitty}/bin/kitty" # Kitty
          "$mod, E, exec, ${pkgs.nautilus}/bin/nautilus" # Nautilus
          "$mod, B, exec, ${pkgs.librewolf}/bin/librewolf" # Librewolf
          "$mod, L, exec, ${pkgs.hyprlock}/bin/hyprlock" # Lock
          "$mod, X, exec, power-menu" # Powermenu
          "$mod, SPACE, exec, launcher" # Launcher
          "SUPER_SHIFT, SPACE, exec, hyprfocus-toggle" # Toggle HyprFocus

          # Window management
          "$mod, Q, killactive," # Close window
          "$mod, T, togglefloating," # Toggle Floating
          "$mod, F, fullscreen" # Toggle Fullscreen

          # Focus movement (vim keys)
          "$mod, h, movefocus, l" # Move focus left
          "$mod, l, movefocus, r" # Move focus Right
          "$mod, k, movefocus, u" # Move focus Up
          "$mod, j, movefocus, d" # Move focus Down

          # Focus movement (arrow keys)
          "$mod, left, movefocus, l" # Move focus left
          "$mod, right, movefocus, r" # Move focus Right
          "$mod, up, movefocus, u" # Move focus Up
          "$mod, down, movefocus, d" # Move focus Down

          # Monitor management
          "SUPER_SHIFT, up, focusmonitor, -1" # Focus previous monitor
          "SUPER_SHIFT, down, focusmonitor, 1" # Focus next monitor
          
          # Master layout
          "SUPER_SHIFT, left, layoutmsg, addmaster" # Add to master
          "SUPER_SHIFT, right, layoutmsg, removemaster" # Remove from master

          # Screenshots
          "$mod, PRINT, exec, screenshot window" # Screenshot window
          ", PRINT, exec, screenshot monitor" # Screenshot monitor
          "SUPER_SHIFT, PRINT, exec, screenshot region" # Screenshot region
          "ALT, PRINT, exec, screenshot region swappy" # Screenshot region then edit

          # Utilities
          "SUPER_SHIFT, S, exec, ${pkgs.librewolf}/bin/librewolf :open $(rofi --show dmenu -L 1 -p ' Search on internet')" # Search on internet with rofi
          "SUPER_SHIFT, C, exec, clipboard" # Clipboard picker with rofi
          "$mod, F2, exec, night-shift" # Toggle night shift
        ];

        # Mouse bindings
        bindm = [
          "$mod, mouse:272, movewindow" # Move Window (mouse)
          "$mod, mouse:273, resizewindow" # Resize Window (mouse)
        ];

        # Locked bindings (work even when locked)
        bindl = [
          ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" # Toggle Mute
          ", switch:on:Lid Switch, exec, hyprctl keyword monitor 'eDP-1, disable'"
          ", switch:off:Lid Switch, exec, hyprctl keyword monitor 'eDP-1, preferred, auto, auto'"
        ];

        # Repeat bindings (hold to repeat)
        bindle = [
          ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0" # Sound Up
          ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" # Sound Down
          ", XF86MonBrightnessUp, exec, brightness-up" # Brightness Up
          ", XF86MonBrightnessDown, exec, brightness-down" # Brightness Down
        ];
      };
    };
  };
}
