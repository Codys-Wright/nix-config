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
        # Window rules
        windowrule = [
          # Workspace assignments based on application
          "class:(obsidian), workspace name:Notes"
          "title:(.*YouTube.*), workspace name:Media"
          "title:(.*ChatGPT.*), workspace name:AI"
          "title:(.*Gmail.*), workspace name:Communication"

          # Floating windows
          "class:(pavucontrol), float"
          "class:(blueman-manager), float"
          "class:(nm-connection-editor), float"
          "title:(Save File), float"
          "title:(Open File), float"

          # Picture-in-picture and popups
          "title:(Picture-in-Picture), float"
          "title:(Picture-in-Picture), pin"

          # Gaming and media applications
          "class:(steam_app.*), fullscreen"
          "class:(steam), workspace name:VideoGame"
          "class:(steam), title:(Steam)$, workspace name:VideoGameLauncher"
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
