/*
Hyprland environment aggregator
*/
{
  FTS,
  lib,
  ...
}: {
  FTS.desktop._.environment._.hyprland = {
    description = "Hyprland desktop environment, including core and keybinds";

    nixos = {
      # Enable Hyprland
      programs.hyprland = {
        enable = true;
      };
    };

    homeManager = {pkgs, ...}: {
      wayland.windowManager.hyprland = {
        enable = true;
        xwayland.enable = true;

        settings = let
          animationDuration = 2.5;
          borderDuration = 1.0;
        in {
          "$mod" = "super";
          "$shiftmod" = "super_shift";

          monitor = lib.mkForce [
            "DP-4, 5120x1440@240, 0x0, 1.00"
            "DP-5,2560x1440@180,0x1440,1.00"
            "HDMI-A-2,2560x1440@60,2560x1440,1.00"
          ];

          # cursor = {
          #   no_hardware_cursors = true;
          # };

          general = {
            resize_on_border = true;
            gaps_in = 3;
            gaps_out = 5;
            border_size = 1;
            layout = "master";
          };

          debug.disable_logs = false;

          decoration = {
            active_opacity = 0.9;
            inactive_opacity = 0.8;
            rounding = 10;
            shadow = {
              enabled = true;
              range = 20;
              render_power = 3;
            };
            blur.enabled = true;
            border_part_of_window = true;
          };

          master = {
            new_status = true;
            allow_small_split = true;
            mfact = 0.5;
          };

          misc = {
            vfr = true;
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            disable_autoreload = true;
            focus_on_activate = true;
            new_window_takes_over_fullscreen = 2;
          };

          input = {
            kb_layout = "us";
            kb_variant = "altgr-intl";
            follow_mouse = 1;
            sensitivity = 0.0;
            repeat_delay = 300;
            repeat_rate = 50;

            touchpad = {
              natural_scroll = true;
              #clickfinger_behavior = true;
              tap-to-click = true;
            };
          };

          bind = lib.mkForce [
            "$mod,RETURN, exec, ${pkgs.kitty}/bin/kitty" # Kitty
            "$mod,E, exec, ${pkgs.nautilus}/bin/nautilus" # Nautilus
            "$mod,B, exec, ${pkgs.librewolf}/bin/librewolf" # Librewolf
            "$mod,L, exec, ${pkgs.hyprlock}/bin/hyprlock" # Lock
            "$mod,X, exec, power-menu" # Powermenu
            "$mod,SPACE, exec, launcher" # Launcher
            "$shiftMod,SPACE, exec, hyprfocus-toggle" # Toggle HyprFocus

            "$mod,Q, killactive," # Close window
            "$mod,T, togglefloating," # Toggle Floating
            "$mod,F, fullscreen" # Toggle Fullscreen

            "$mod,h, movefocus, l" # Move focus left
            "$mod,l, movefocus, r" # Move focus Right
            "$mod,k, movefocus, u" # Move focus Up
            "$mod,j, movefocus, d" # Move focus Down

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
          ];

          bindm = lib.mkForce [
            "$mod,mouse:272, movewindow" # Move Window (mouse)
            "$mod,mouse:273, resizewindow" # Resize Window (mouse)
          ];

          bindl = lib.mkForce [
            ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle" # Toggle Mute
            ",switch:on:Lid Switch, exec, hyprctl keyword monitor 'eDP-1, disable'"
            ",switch:off:Lid Switch, exec, hyprctl keyword monitor 'eDP-1, preferred, auto, auto'"
          ];

          bindle = lib.mkForce [
            ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0" # Sound Up
            ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" # Sound Down
            ",XF86MonBrightnessUp, exec, brightness-up" # Brightness Up
            ",XF86MonBrightnessDown, exec, brightness-down" # Brightness Down
          ];

          animations = {
            enabled = true;
            bezier = lib.mkForce [
              "linear, 0, 0, 1, 1"
              "md3_standard, 0.2, 0, 0, 1"
              "md3_decel, 0.05, 0.7, 0.1, 1"
              "md3_accel, 0.3, 0, 0.8, 0.15"
              "overshot, 0.05, 0.9, 0.1, 1.1"
              "crazyshot, 0.1, 1.5, 0.76, 0.92"
              "hyprnostretch, 0.05, 0.9, 0.1, 1.0"
              "menu_decel, 0.1, 1, 0, 1"
              "menu_accel, 0.38, 0.04, 1, 0.07"
              "easeInOutCirc, 0.85, 0, 0.15, 1"
              "easeOutCirc, 0, 0.55, 0.45, 1"
              "easeOutExpo, 0.16, 1, 0.3, 1"
              "softAcDecel, 0.26, 0.26, 0.15, 1"
              "md2, 0.4, 0, 0.2, 1"
            ];

            animation = lib.mkForce [
              "windows, 1, ${toString animationDuration}, md3_decel, popin 60%"
              "windowsIn, 1, ${toString animationDuration}, md3_decel, popin 60%"
              "windowsOut, 1, ${toString animationDuration}, md3_accel, popin 60%"
              "border, 1, ${toString borderDuration}, default"
              "fade, 1, ${toString animationDuration}, md3_decel"
              "layersIn, 1, ${toString animationDuration}, menu_decel, slide"
              "layersOut, 1, ${toString animationDuration}, menu_accel"
              "fadeLayersIn, 1, ${toString animationDuration}, menu_decel"
              "fadeLayersOut, 1, ${toString animationDuration}, menu_accel"
              "workspaces, 1, ${toString animationDuration}, menu_decel, slide"
              "specialWorkspace, 1, ${toString animationDuration}, md3_decel, slidevert"
            ];
          };
        };
      };
    };
  };
}
