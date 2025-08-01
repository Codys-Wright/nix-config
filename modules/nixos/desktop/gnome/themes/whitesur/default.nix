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
  cfg = config.${namespace}.desktop.gnome.themes.whitesur;
in
{
  options.${namespace}.desktop.gnome.themes.whitesur = with types; {
    enable = mkBoolOpt false "Enable WhiteSur theme for GNOME";
    variant = mkOpt (types.enum [ "light" "dark" ]) "light" "WhiteSur theme variant for GNOME";
  };

  config = mkIf cfg.enable {
    # WhiteSur theme packages
    environment.systemPackages = with pkgs; [
      # WhiteSur theme packages
      whitesur-gtk-theme
      whitesur-icon-theme
      whitesur-cursors
      
      # Required build dependencies for WhiteSur
      sassc
      glib
      libxml2
      
      # Optional dependencies for WhiteSur
      imagemagick  # For GDM theme tweak
      dialog       # For installation in dialog mode
      optipng      # For asset rendering
      inkscape     # For asset rendering
      
      # Recommended GNOME Shell extensions for WhiteSur
      gnomeExtensions.user-themes      # Enable gnome-shell theme
      gnomeExtensions.dash-to-dock     # Dock extension
      gnomeExtensions.blur-my-shell    # Blur effects
      gnomeExtensions.just-perfection  # Customization
    ];
    
    # Set theme via environment variables
    environment.sessionVariables = {
      GTK_THEME = "WhiteSur-${cfg.variant}";
      XCURSOR_THEME = "WhiteSur-cursors";
    };
    
    # Override Stylix GTK theme to use WhiteSur instead
    home-manager.users.cody.stylix = {
      targets.gtk.enable = mkForce false;  # Disable Stylix GTK theme
    };
  };
} 