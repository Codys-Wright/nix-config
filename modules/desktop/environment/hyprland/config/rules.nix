# Hyprland window rules, workspace rules, and layer rules
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.config._.rules = {
    description = "Hyprland window rules, workspace rules, and layer rules";

    homeManager = {
      wayland.windowManager.hyprland.settings = {
        # Monitor variables for workspace assignments
        "$primaryMonitor" = "DP-4";
        "$secondaryMonitor" = "DP-5";
        "$tertiaryMonitor" = "HDMI-A-2";
        # Window rules (v2 format recommended)
        windowrulev2 = [
          # Workspace assignments based on application
          "workspace name:Notes, class:(obsidian)"
          "workspace name:Media, title:(.*YouTube.*)"
          "workspace name:AI, title:(.*ChatGPT.*)"
          "workspace name:Communication, title:(.*Gmail.*)"

          # Floating windows
          "float, class:(pavucontrol)"
          "float, class:(blueman-manager)"
          "float, class:(nm-connection-editor)"
          "float, title:(Save File)"
          "float, title:(Open File)"

          # Picture-in-picture and popups
          "float, title:(Picture-in-Picture)"
          "pin, title:(Picture-in-Picture)"

          # Gaming and media applications
          "fullscreen, class:(steam_app.*)"
          "workspace name:VideoGame, class:(steam)"
          "workspace name:VideoGameLauncher, class:(steam), title:(Steam)$"
        ];

        # Workspace rules with monitor assignments
        workspace = [
          # General purpose workspaces
          "name:Media, monitor:$primaryMonitor, persistent:true"
          "name:Communication, monitor:$secondaryMonitor, persistent:true"
          "name:Research, monitor:$tertiaryMonitor, persistent:true"
          "name:AI, monitor:$primaryMonitor, persistent:true"
          "name:Notes, monitor:$secondaryMonitor, persistent:true"

          # Video editing workspaces
          "name:VideoEditing-Primary, monitor:$primaryMonitor, persistent:true"
          "name:VideoEditing-Secondary, monitor:$secondaryMonitor, persistent:true"
          "name:VideoEditing-Tertiary, monitor:$tertiaryMonitor, persistent:true"

          # Music production workspaces
          "name:MusicProduction-Primary, monitor:$primaryMonitor, persistent:true"
          "name:MusicProduction-Secondary, monitor:$secondaryMonitor, persistent:true"
          "name:MusicProduction-Tertiary, monitor:$tertiaryMonitor, persistent:true"

          # Gaming workspaces
          "name:VideoGame, monitor:$primaryMonitor, persistent:true"
          "name:VideoGameLauncher, monitor:$secondaryMonitor, persistent:true"

          # Development workspace
          "name:Dev-Preview, monitor:$primaryMonitor, persistent:true"
        ];

        # Layer rules
        # Example: layerrule = blur, waybar
        layerrule = [
          # Add your layer rules here
        ];
      };
    };
  };
}
