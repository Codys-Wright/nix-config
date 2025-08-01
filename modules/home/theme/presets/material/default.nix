{
  config,
  lib,
  pkgs,
  inputs,
  namespace,
  ...
}: let
  inherit (lib) mkIf mkMerge toSentenceCase mkForce;
  cfg = config.${namespace}.theme;
  
  # Helper function for forcable values
  mkForcable = value:
    if cfg.force
    then mkForce value
    else value;
in {
  config = mkIf (cfg.preset == "material") (mkMerge [
    # Colors
    (mkIf cfg.targets.colors.enable {
      stylix.override = mkForcable {
        base00 = if cfg.polarity == "light" then "fafafa" else "212121";
        base01 = if cfg.polarity == "light" then "f5f5f5" else "303030";
        base02 = if cfg.polarity == "light" then "eeeeee" else "424242";
        base03 = if cfg.polarity == "light" then "e0e0e0" else "616161";
        base04 = if cfg.polarity == "light" then "bdbdbd" else "757575";
        base05 = if cfg.polarity == "light" then "424242" else "eeeeee";
        base06 = "f50057";
        base07 = "c51162";
        base08 = "d50000";
        base09 = "ff6d00";
        base0A = "ffab00";
        base0B = "00c853";
        base0C = "00b8d4";
        base0D = "2196f3";
        base0E = "aa00ff";
        base0F = "c51162";
      };
    })

    # Fonts
    (mkIf cfg.targets.fonts.enable {
      stylix.fonts = {
        sansSerif = {
          package = mkForcable pkgs.roboto;
          name = mkForcable "Roboto";
        };
        serif = {
          package = mkForcable pkgs.roboto-slab;
          name = mkForcable "Roboto Slab";
        };
        monospace = {
          package = mkForcable pkgs.roboto-mono;
          name = mkForcable "Roboto Mono";
        };
        emoji = {
          package = mkForcable pkgs.noto-fonts-emoji;
          name = mkForcable "Noto Color Emoji";
        };
        sizes = {
          applications = 14;
          desktop = 14;
          popups = 14;
          terminal = 14;
        };
      };
    })

    # Icons
    (mkIf cfg.targets.icons.enable {
      stylix.iconTheme = {
        enable = true;
        package = mkForcable pkgs.papirus-icon-theme;
        light = mkForcable "Papirus-Light";
        dark = mkForcable "Papirus-Dark";
      };
    })

    # Cursor
    (mkIf cfg.targets.cursor.enable {
      stylix.cursor = {
        package = mkForcable pkgs.bibata-cursors;
        name = mkForcable "Bibata-Original-Ice";
        size = 24;
      };
    })

    # GTK Theme
    (mkIf cfg.targets.gtk.enable {
      gtk.theme = {
        name = lib.mkForce (mkForcable "Material-${toSentenceCase cfg.polarity}");
        package = lib.mkForce (mkForcable pkgs.material-gtk-theme);
      };
    })

    # Shell/Desktop
    (mkIf cfg.targets.shell.enable (mkMerge [
      # GNOME-specific theming
      (mkIf (lib.elem "gnome" cfg.availableDesktops) {
        home.packages = with pkgs.gnomeExtensions; mkForcable [
          blur-my-shell
          user-themes
          dash-to-dock
          arc-menu
          desktop-icons-ng-ding
          wiggle
        ];
        dconf.settings = mkForcable {
          "org/gnome/shell/extensions/user-theme" = {
            name = lib.mkForce "Material-${toSentenceCase cfg.polarity}";
          };
          "org/gnome/desktop/wm/preferences" = {
            button-layout = "close,minimize,maximize:appmenu";
          };
          "org/gnome/shell/extensions/arcmenu" = {
            arc-menu-icon = 64;
            menu-layout = "Material";
          };
          "org/gnome/shell/extensions/dash-to-dock" = {
            dash-max-icon-size = 64;
            dock-fixed = true;
            multi-monitur = true;
            scroll-action = "switch-workspace";
            show-show-apps-button = false;
          };
        };
      })
      
      # KDE-specific theming
      (mkIf (lib.elem "kde" cfg.availableDesktops) {
        home.packages = with pkgs; mkForcable [
          material-kde-theme
          papirus-icon-theme
          bibata-cursors
        ];
        qt = {
          enable = true;
          platformTheme.name = "kde";
          style.name = "breeze";
        };
        xdg.configFile = mkForcable {
          "kglobalshortcutsrc".source = ./kde/kglobalshortcutsrc;
          "kwinrc".source = ./kde/kwinrc;
          "plasmarc".source = ./kde/plasmarc;
        };
      })
      
      # Hyprland-specific theming
      (mkIf (lib.elem "hyprland" cfg.availableDesktops) {
        home.packages = with pkgs; mkForcable [
          waybar
          rofi-wayland
          wl-clipboard
          grim
          slurp
        ];
        xdg.configFile = mkForcable {
          "hypr/hyprland.conf".source = ./hyprland/hyprland.conf;
          "waybar/config".source = ./hyprland/waybar-config;
          "waybar/style.css".source = ./hyprland/waybar-style.css;
        };
      })
    ]))
  ]);
} 