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
      type = types.enum ["whitesur" "windows" "material" "adwaita" "breeze" "stylix"];
      default = "whitesur";
      example = "windows";
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
    
    # Stylix specific options
    stylix = {
      enable = mkEnableOption "Stylix integration";
      autoEnable = mkOption {
        description = "Auto-enable stylix targets";
        type = types.bool;
        default = true;
      };
      base16Scheme = mkOption {
        description = "Base16 scheme path";
        type = types.path;
        default = ./base16/catppuccin/custom.yaml;
      };
      image = mkOption {
        description = "Wallpaper image path";
        type = types.path;
        default = ./wallpapers/sports.png;
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # Disable the old stylix program when theme system is enabled
    {
      ${namespace}.programs.stylix = lib.mkForce { enable = false; };
    }
    
    # Stylix configuration
    (mkIf cfg.stylix.enable {
      stylix = {
        enable = true;
        autoEnable = cfg.stylix.autoEnable;
        base16Scheme = cfg.stylix.base16Scheme;
        image = cfg.stylix.image;
        polarity = cfg.polarity;
        targets = {
          kitty.enable = false;
          waybar.enable = false;
          hyprlock.enable = false;
          neovim.enable = false;
          librewolf = {
            enable = true;
            profileNames = [ "default" ];
          };
          zen-browser = {
            enable = true;
            profileNames = [ "default" ];
          };
        };
      };
    })
  ]);
} 