# Hyprcursor - Hyprland cursor theme system
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland._.plugins._.hyprcursor = {
    description = "Hyprcursor configuration for Hyprland";

    homeManager = {
      home.sessionVariables = {
        # Use hyprcursor instead of xcursor
        HYPRCURSOR_THEME = "MacTahoe-dark-cursors";
        HYPRCURSOR_SIZE = "24";
      };

      # Hyprcursor configuration file
      home.file.".config/hypr/hyprcursor.conf".text = ''
        # Hyprcursor configuration
        # Theme will be loaded from ~/.local/share/icons or /usr/share/icons
        
        # Default cursor theme
        theme = MacTahoe-dark-cursors
        
        # Cursor size
        size = 24
      '';
    };
  };
}
