{
  config,
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkMerge toSentenceCase mkOption mkEnableOption mkForce types id;
  
  # Helper function to create target options
  mkTargetOption = description:
    mkOption {
      description = "Whether to enable the ${description} target.";
      type = types.bool;
      default = true;
      example = false;
    };
  
  cfg = config.${namespace}.theme;
  
  # Helper function for forcable values
  mkForcable = value:
    if cfg.force
    then mkForce value
    else value;
in {
  options.${namespace}.theme = {
    enable = mkEnableOption "Theme system";
    force = mkEnableOption "overriding options";
    
    # Preset theme selection
    preset = mkOption {
      description = "Theme preset to use";
      type = types.enum ["whitesur" "windows" "material" "adwaita" "breeze" "stylix" "catppuccin"];
      default = "whitesur";
      example = "catppuccin";
    };
    
    # Desktop environment detection (derived from system config)
    desktop = mkOption {
      description = "Primary desktop environment to theme for (derived from system config)";
      type = types.enum ["gnome" "kde" "hyprland"];
      default = config.${namespace}.desktop.type or "gnome";
      example = "kde";
    };
    
    # Available desktop environments for theming
    availableDesktops = mkOption {
      description = "Available desktop environments for theming (derived from system config)";
      type = types.listOf (types.enum ["gnome" "kde" "hyprland"]);
      default = config.${namespace}.desktop.environments or [config.${namespace}.desktop.type or "gnome"];
      example = ["gnome" "kde"];
    };
    
    # Individual components
    targets = {
      colors.enable = mkTargetOption "color palette";
      fonts.enable = mkTargetOption "fonts";
      icons.enable = mkTargetOption "icons";
      cursor.enable = mkTargetOption "cursor";
      gtk.enable = mkTargetOption "GTK";
      shell.enable = mkTargetOption "desktop shell";
      wallpaper.enable = mkTargetOption "wallpaper";
    };
    
    polarity = mkOption {
      description = "Polarity of the color palette";
      type = types.enum ["light" "dark"];
      default = "dark";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Theme presets are automatically available via Snowfall Lib
    # Each preset handles its own stylix configuration
  ]);
} 