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
    # Import the base WhiteSur theme
    imports = [
      ../../../../themes/whitesur
    ];
    
    # Enable WhiteSur theme with GNOME-specific variant
    ${namespace}.themes.whitesur = {
      enable = true;
      variant = cfg.variant;
    };
    
    # GNOME-specific theme configurations
    environment.sessionVariables = {
      # GNOME Shell theme
      GNOME_SHELL_THEME = "WhiteSur-${cfg.variant}";
      
      # Additional GNOME theme variables
      GTK_THEME = "WhiteSur-${cfg.variant}";
      XCURSOR_THEME = "WhiteSur-cursors";
    };
    
    # GNOME Shell extensions for better theme integration
    environment.systemPackages = with pkgs; [
      gnomeExtensions.blur-my-shell
      gnomeExtensions.just-perfection
    ];
  };
} 