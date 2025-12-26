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

        # Workspace name variables
        "$ws1" = "name:Media";
        "$ws2" = "name:Communication";
        "$ws3" = "name:Research";
        "$ws4" = "name:AI";
        "$ws5" = "name:Notes";
        "$ws6" = "name:VideoEditing-Primary";
        "$ws7" = "name:VideoEditing-Secondary";
        "$ws8" = "name:VideoEditing-Tertiary";
        "$ws9" = "name:MusicProduction-Primary";
        "$ws0" = "name:MusicProduction-Secondary";
        "$wsM" = "name:MusicProduction-Tertiary";
        "$wsG" = "name:VideoGame";
        "$wsL" = "name:VideoGameLauncher";
        "$wsP" = "name:Dev-Preview";

        # Regular keybindings
        bind = [
          # Applications (with run-or-raise)
          "$mod, RETURN, exec, run-or-raise kitty" # Kitty terminal (default)
          "$mod, T, exec, run-or-raise ghostty" # Ghostty terminal
          "$mod, N, exec, run-or-raise obsidian" # Obsidian notes
          "$mod, B, exec, run-or-raise brave" # Brave browser
          "$mod, M, exec, run-or-raise WebApp-youtube firefox" # YouTube webapp
          "$mod, A, exec, run-or-raise WebApp-chatgpt firefox" # ChatGPT webapp
          "SUPER_ALT, M, exec, run-or-raise WebApp-gmail firefox" # Gmail webapp
          # "$mod ALT, L, exec, ${pkgs.hyprlock}/bin/hyprlock" # Lock screen
          "$mod, X, exec, power-menu" # Powermenu
          "$mod, SPACE, exec, walker" # Application launcher (Walker)
          "$mod, W, exec, hyprland-workflow-switcher --select 'walker --dmenu --placeholder \"Select Workflow:\"'" # Workflow switcher
          "SUPER_SHIFT, A, exec, hyprland-manager" # Hyprland Manager (Appearance)
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

          # Window movement (Super + Ctrl + arrows/hjkl)
          "SUPER_CTRL, left, movewindow, l" # Move window left
          "SUPER_CTRL, right, movewindow, r" # Move window right
          "SUPER_CTRL, up, movewindow, u" # Move window up
          "SUPER_CTRL, down, movewindow, d" # Move window down
          "SUPER_CTRL, h, movewindow, l" # Move window left (vim)
          "SUPER_CTRL, l, movewindow, r" # Move window right (vim)
          "SUPER_CTRL, k, movewindow, u" # Move window up (vim)
          "SUPER_CTRL, j, movewindow, d" # Move window down (vim)

          # Window resizing (Super + Shift + arrows/hjkl)
          "SUPER_SHIFT, left, resizeactive, -50 0" # Resize left
          "SUPER_SHIFT, right, resizeactive, 50 0" # Resize right
          "SUPER_SHIFT, up, resizeactive, 0 -50" # Resize up
          "SUPER_SHIFT, down, resizeactive, 0 50" # Resize down
          "SUPER_SHIFT, h, resizeactive, -50 0" # Resize left (vim)
          "SUPER_SHIFT, l, resizeactive, 50 0" # Resize right (vim)
          "SUPER_SHIFT, k, resizeactive, 0 -50" # Resize up (vim)
          "SUPER_SHIFT, j, resizeactive, 0 50" # Resize down (vim)

          # Window swapping (Super + Alt + arrows/hjkl)
          "SUPER_ALT, left, swapwindow, l" # Swap window left
          "SUPER_ALT, right, swapwindow, r" # Swap window right
          "SUPER_ALT, up, swapwindow, u" # Swap window up
          "SUPER_ALT, down, swapwindow, d" # Swap window down
          "SUPER_ALT, h, swapwindow, l" # Swap window left (vim)
          "SUPER_ALT, l, swapwindow, r" # Swap window right (vim)
          "SUPER_ALT, k, swapwindow, u" # Swap window up (vim)
          "SUPER_ALT, j, swapwindow, d" # Swap window down (vim)

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
          "SUPER_SHIFT, S, exec, night-shift" # Toggle night shift
          "SUPER_SHIFT, C, exec, clipboard" # Clipboard picker with rofi
          "$mod, F2, exec, night-shift" # Toggle night shift

          # Workspace Navigation (General)
          "$mod, 1, workspace, $ws1"
          "$mod, 2, workspace, $ws2"
          "$mod, 3, workspace, $ws3"
          "$mod, 4, workspace, $ws4"
          "$mod, 5, workspace, $ws5"

          # Workspace Navigation (Video Editing)
          "$mod, 6, workspace, $ws6"
          "$mod, 7, workspace, $ws7"
          "$mod, 8, workspace, $ws8"

          # Workspace Navigation (Music Production)
          "$mod, 9, workspace, $ws9"
          "$mod, 0, workspace, $ws0"
          "SUPER_ALT, M, workspace, $wsM"

          # Workspace Navigation (Gaming)
          "SUPER_ALT, V, workspace, $wsG"
          "SUPER_ALT, X, workspace, $wsL"

          # Workspace Navigation (Development)
          "SUPER_ALT, P, workspace, $wsP"

          # Move windows to workspaces
          "SUPER_SHIFT, 1, movetoworkspace, $ws1"
          "SUPER_SHIFT, 2, movetoworkspace, $ws2"
          "SUPER_SHIFT, 3, movetoworkspace, $ws3"
          "SUPER_SHIFT, 4, movetoworkspace, $ws4"
          "SUPER_SHIFT, 5, movetoworkspace, $ws5"
          "SUPER_SHIFT, 6, movetoworkspace, $ws6"
          "SUPER_SHIFT, 7, movetoworkspace, $ws7"
          "SUPER_SHIFT, 8, movetoworkspace, $ws8"
          "SUPER_SHIFT, 9, movetoworkspace, $ws9"
          "SUPER_SHIFT, 0, movetoworkspace, $ws0"
          "SUPER_SHIFT_ALT, M, movetoworkspace, $wsM"
          "SUPER_SHIFT_ALT, V, movetoworkspace, $wsG"
          "SUPER_SHIFT_ALT, X, movetoworkspace, $wsL"
          "SUPER_SHIFT_ALT, P, movetoworkspace, $wsP"
        ];

        # Mouse bindings
        bindm = [
          "$mod, mouse:272, movewindow" # Move Window (mouse)
          "$mod, mouse:273, resizeactive" # Resize Window (mouse)
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
