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
    variant = mkOpt (types.enum [ "light" "dark" ]) "light" "WhiteSur theme variant for GNOME";
  };

  config = mkIf config.${namespace}.desktop.gnome.themes.enable {
    # WhiteSur theme packages and GNOME extensions
    environment.systemPackages = with pkgs; [
      # WhiteSur theme packages
      whitesur-gtk-theme
      whitesur-icon-theme
      whitesur-cursors
      
      # GNOME Shell extensions for better theme integration
      gnomeExtensions.blur-my-shell
      gnomeExtensions.just-perfection
    ];
    
    # GNOME-specific theme configurations
    environment.sessionVariables = {
      # GNOME Shell theme
      GNOME_SHELL_THEME = "WhiteSur-${cfg.variant}";
      
      # Additional GNOME theme variables
      GTK_THEME = "WhiteSur-${cfg.variant}";
      XCURSOR_THEME = "WhiteSur-cursors";
    };
    
    # GTK theme configuration
    gtk = {
      enable = true;
      theme = {
        name = "WhiteSur-${cfg.variant}";
        package = pkgs.whitesur-gtk-theme;
      };
      iconTheme = {
        name = "WhiteSur";
        package = pkgs.whitesur-icon-theme;
      };
      cursorTheme = {
        name = "WhiteSur-cursors";
        package = pkgs.whitesur-cursors;
      };
    };
  };
} 