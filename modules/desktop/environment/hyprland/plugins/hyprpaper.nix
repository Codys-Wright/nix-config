# Hyprpaper - Hyprland wallpaper daemon configuration
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.plugins._.hyprpaper = {
    description = "Hyprpaper wallpaper daemon configuration for Hyprland";

    homeManager = {
      services.hyprpaper = {
        enable = true;
        
        settings = {
          ipc = "on";
          splash = false;
          
          # Preload wallpapers
          preload = [
            # Add your wallpaper paths here
            # Example: "~/Pictures/wallpapers/main.png"
          ];

          # Set wallpapers per monitor
          wallpaper = [
            # Add your monitor-wallpaper mappings here
            # Example: "DP-4,~/Pictures/wallpapers/main.png"
            # Example: "DP-5,~/Pictures/wallpapers/secondary.png"
          ];
        };
      };
    };
  };
}
