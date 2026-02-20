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
        # Window rules (Hyprland 0.53+ syntax)
        windowrule = [
          # Workspace assignments based on application
          "workspace name:Notes, match:class obsidian"
          "workspace name:Media, match:title .*YouTube.*"
          "workspace name:AI, match:title .*ChatGPT.*"
          "workspace name:Communication, match:title .*Gmail.*"

          # Floating windows
          "float on, match:class pavucontrol"
          "float on, match:class blueman-manager"
          "float on, match:class nm-connection-editor"
          "float on, match:title Save File"
          "float on, match:title Open File"

          # Picture-in-picture and popups
          "float on, match:title Picture-in-Picture"
          "pin on, match:title Picture-in-Picture"

          # Gaming and media applications
          "fullscreen on, match:class steam_app.*"
          "workspace name:VideoGame, match:class steam"
          "workspace name:VideoGameLauncher, match:class steam, match:title Steam$"
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

        # Layer rules (Hyprland 0.53+ syntax)
        layerrule = [
          # Example: "blur on, match:namespace waybar"
        ];
      };
    };
  };
}
