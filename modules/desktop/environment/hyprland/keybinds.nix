# Hyprland Keybind Implementation
# Consumes the desktop keybind abstractions and generates Hyprland-specific bindings
{ ... }:
{
  den.aspects.hyprland-keybinds = {
    description = "Hyprland desktop environment with abstracted keybind support";

    homeManager = { config, pkgs, lib, ... }:
    let
      cfg = config.desktop.keybinds;

      # Helper function to convert abstract actions to Hyprland commands
      hyprlandAction = action: {
        "close-window" = "killactive,";
        "toggle-floating" = "togglefloating,";
        "toggle-fullscreen" = "fullscreen";
        "focus-left" = "movefocus, l";
        "focus-down" = "movefocus, d";
        "focus-up" = "movefocus, u";
        "focus-right" = "movefocus, r";
      }.${action} or action;

      # Convert keybind format from abstraction to Hyprland format
      hyprlandKeybind = key: modifier: "${modifier},${key}";

      # Generate application bindings for Hyprland
      appBinds = lib.mapAttrsToList (binding: command:
        "${binding}, exec, ${command}"
      ) cfg.generateAppBindings;

      # Generate window management bindings for Hyprland
      windowBinds = lib.mapAttrsToList (binding: action:
        "${binding}, ${hyprlandAction action}"
      ) cfg.generateWindowBindings;

      # Additional Hyprland-specific bindings
      hyprlandSpecificBinds = with cfg; [
        # Arrow key alternatives for focus
        "${mod},left, movefocus, l"
        "${mod},right, movefocus, r"
        "${mod},up, movefocus, u"
        "${mod},down, movefocus, d"

        # Monitor focus
        "${shiftMod},up, focusmonitor, -1"
        "${shiftMod},down, focusmonitor, 1"

        # Layout management
        "${shiftMod},left, layoutmsg, addmaster"
        "${shiftMod},right, layoutmsg, removemaster"

        # Screenshots
        "${mod},PRINT, exec, screenshot window"
        ",PRINT, exec, screenshot monitor"
        "${shiftMod},PRINT, exec, screenshot region"
        "${altMod},PRINT, exec, screenshot region swappy"

        # Special functions
        "${shiftMod},S, exec, ${cfg.apps.browser.command} $(rofi --show dmenu -L 1 -p ' Search on internet')"
        "${shiftMod},C, exec, clipboard"
        "${mod},F2, exec, night-shift"
      ];

      # Workspace bindings (1-9)
      workspaceBinds = builtins.concatLists (
        builtins.genList (i:
          let ws = i + 1; in [
            "${cfg.mod},code:1${toString i}, workspace, ${toString ws}"
            "${cfg.mod} SHIFT,code:1${toString i}, movetoworkspace, ${toString ws}"
          ]
        ) 9
      );

    in {
      # Ensure the keybind abstraction is loaded
      imports = [ ../../../abstractions/keybinds.nix ];

      wayland.windowManager.hyprland = {
        enable = lib.mkDefault true;

        settings = {
          # Define modifier variables for Hyprland
          "$mod" = "SUPER";
          "$shiftMod" = "SUPER_SHIFT";

          # Combine all binding types
          bind = appBinds ++ windowBinds ++ hyprlandSpecificBinds ++ workspaceBinds;

          # Mouse bindings
          bindm = [
            "$mod,mouse:272, movewindow"
            "$mod,mouse:273, resizewindow"
          ];

          # Locked bindings (work even when locked)
          bindl = [
            ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
            ",switch:on:Lid Switch, exec, hyprctl keyword monitor 'eDP-1, disable'"
            ",switch:off:Lid Switch, exec, hyprctl keyword monitor 'eDP-1, prefered, auto, auto'"
          ];

          # Repeat bindings (hold to repeat)
          bindle = [
            ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1.0"
            ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
            ",XF86MonBrightnessUp, exec, brightness-up"
            ",XF86MonBrightnessDown, exec, brightness-down"
          ];
        };
      };

      # Override system commands to be Hyprland-specific
      desktop.keybinds.system.lock.command = lib.mkDefault "${pkgs.hyprlock}/bin/hyprlock";

      # Install Hyprland-specific packages
      home.packages = with pkgs; [
        hyprlock
        hypridle
        hyprpicker
        hyprshot
      ];
    };
  };
}
