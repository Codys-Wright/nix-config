{
  config,
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkMerge toSentenceCase mkForce mkOption;
  cfg = config.${namespace}.theme;
  
  # Helper function for forcable values
  mkForcable = value:
    if cfg.force
    then mkForce value
    else value;
in {
  options.${namespace}.theme.catppuccin = with lib.types; {
    # Stylix configuration options
    stylix = {
      enable = mkOption {
        description = "Enable stylix integration for catppuccin theme";
        type = bool;
        default = true;
      };
      base16Scheme = mkOption {
        description = "Base16 scheme file to use";
        type = enum ["custom" "mocha" "macchiato" "frappe" "latte"];
        default = "custom";
      };
      image = mkOption {
        description = "Wallpaper image path";
        type = path;
        default = ../../wallpapers/catppuccin.jpg;
      };
      # Font configuration
      fonts = {
        monospace = mkOption {
          description = "Monospace font configuration";
          type = attrs;
          default = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font Mono";
          };
        };
        sansSerif = mkOption {
          description = "Sans-serif font configuration";
          type = attrs;
          default = {
            package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
            name = "SFProDisplay Nerd Font";
          };
        };
        serif = mkOption {
          description = "Serif font configuration";
          type = attrs;
          default = {
            package = inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
            name = "SFProDisplay Nerd Font";
          };
        };
        emoji = mkOption {
          description = "Emoji font configuration";
          type = attrs;
          default = {
            package = pkgs.noto-fonts-emoji;
            name = "Noto Color Emoji";
          };
        };
        sizes = mkOption {
          description = "Font sizes";
          type = attrs;
          default = {
            applications = 13;
            desktop = 13;
            popups = 13;
            terminal = 13;
          };
        };
      };
      # Cursor configuration
      cursor = mkOption {
        description = "Cursor configuration";
        type = attrs;
        default = {
          package = pkgs.bibata-cursors;
          name = "Bibata-Original-Ice";
          size = 24;
        };
      };
      # Icon theme configuration
      iconTheme = mkOption {
        description = "Icon theme configuration";
        type = attrs;
        default = {
          enable = true;
          package = pkgs.papirus-icon-theme;
          light = "Papirus-Light";
          dark = "Papirus-Dark";
        };
      };
    };
  };

  config = mkIf (cfg.preset == "catppuccin") (let
    catppuccinCfg = cfg.catppuccin or {};
    stylixCfg = catppuccinCfg.stylix or {};
    
    # Helper function to get base16 scheme path
    getBase16Scheme = scheme:
      ../../base16/catppuccin/${scheme}.yaml;
  in mkMerge [
    # Stylix integration
    (mkIf stylixCfg.enable {
      stylix = {
        enable = true;
        autoEnable = true;
        base16Scheme = mkForcable (getBase16Scheme stylixCfg.base16Scheme);
        image = mkForcable stylixCfg.image;
        polarity = cfg.polarity;
        
        # Fonts
        fonts = {
          monospace = mkForcable stylixCfg.fonts.monospace;
          sansSerif = mkForcable stylixCfg.fonts.sansSerif;
          serif = mkForcable stylixCfg.fonts.serif;
          emoji = mkForcable stylixCfg.fonts.emoji;
          sizes = mkForcable stylixCfg.fonts.sizes;
        };
        
        # Cursor
        cursor = mkForcable stylixCfg.cursor;
        
        # Icon theme
        iconTheme = mkForcable stylixCfg.iconTheme;
        
        # Targets
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