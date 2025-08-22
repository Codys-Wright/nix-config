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
  options.${namespace}.theme.whitesur = with lib.types; {
    # Stylix configuration options
    stylix = {
      enable = mkOption {
        description = "Enable stylix integration for WhiteSur theme";
        type = bool;
        default = true;
      };
      base16Scheme = mkOption {
        description = "Base16 scheme file to use (WhiteSur colors)";
        type = path;
        default = ../../base16/catppuccin/custom.yaml;
      };
      image = mkOption {
        description = "Wallpaper image path";
        type = path;
        default = "${inputs.whitesur-wallpapers}/4k/WhiteSur-dark.jpg";
      };
    };
    
    # WhiteSur-specific options
    opacity = mkOption {
      description = "Panel opacity for GNOME shell";
      type = enum ["15" "25" "35" "45" "55" "65" "75" "85"];
      default = "15";
      example = "25";
    };
    panelHeight = mkOption {
      description = "Panel height for GNOME shell";
      type = enum ["32" "40" "48" "56" "64"];
      default = "32";
      example = "40";
    };
    activitiesIcon = mkOption {
      description = "Activities icon style";
      type = enum ["standard" "colorful" "white" "ubuntu"];
      default = "standard";
      example = "colorful";
    };
    smallerFont = mkOption {
      description = "Use smaller font size (10pt instead of 11pt)";
      type = bool;
      default = false;
      example = true;
    };
    showAppsNormal = mkOption {
      description = "Use normal show apps button style instead of BigSur style";
      type = bool;
      default = false;
      example = true;
    };
    montereyStyle = mkOption {
      description = "Use macOS Monterey style instead of BigSur";
      type = bool;
      default = false;
      example = true;
    };
    highDefinition = mkOption {
      description = "Use high definition size for high-DPI displays";
      type = bool;
      default = false;
      example = true;
    };
    libadwaita = mkOption {
      description = "Enable GTK4/libadwaita theming";
      type = bool;
      default = false;
      example = true;
    };
    fixedAccent = mkOption {
      description = "Use fixed accent colors instead of adaptive";
      type = bool;
      default = false;
      example = true;
    };
  };

  config = mkIf (cfg.preset == "whitesur") (let
    whitesurCfg = cfg.whitesur or {};
    stylixCfg = whitesurCfg.stylix or {};
  in mkMerge [
    # Stylix integration
    (mkIf stylixCfg.enable {
      stylix = {
        enable = true;
        autoEnable = true;
        base16Scheme = mkForcable stylixCfg.base16Scheme;
        image = mkForcable stylixCfg.image;
        polarity = cfg.polarity;
        
        # Fonts
        fonts = with inputs.apple-fonts.packages.${pkgs.system}; {
          sansSerif = {
            package = mkForcable sf-pro;
            name = mkForcable "SF Pro";
          };
          serif = {
            package = mkForcable sf-pro;
            name = mkForcable "SF Pro";
          };
          monospace = {
            package = mkForcable sf-mono-nerd;
            name = mkForcable "SFMono Nerd Font";
          };
          emoji = {
            package = mkForcable pkgs.noto-fonts-emoji;
            name = mkForcable "Noto Color Emoji";
          };
          sizes = {
            applications = if whitesurCfg.smallerFont then 10 else 13;
            desktop = if whitesurCfg.smallerFont then 10 else 13;
            popups = if whitesurCfg.smallerFont then 10 else 13;
            terminal = if whitesurCfg.smallerFont then 10 else 13;
          };
        };
        
        # Cursor
        cursor = {
          package = mkForcable pkgs.whitesur-cursors;
          name = mkForcable "WhiteSur-cursors";
          size = 24;
        };
        
        # Icon theme
        iconTheme = {
          enable = true;
          package = mkForcable pkgs.whitesur-icon-theme;
          light = mkForcable "WhiteSur-light";
          dark = mkForcable "WhiteSur-dark";
        };
        
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

    # Colors (fallback if stylix is disabled)
    (mkIf (cfg.targets.colors.enable && !stylixCfg.enable) {
      stylix.override = mkForcable {
        base00 = if cfg.polarity == "light" then "ffffff" else "242424";
        base01 = if cfg.polarity == "light" then "f5f5f5" else "333333";
        base02 = if cfg.polarity == "light" then "f1f1f1" else "2a2a2a";
        base03 = if cfg.polarity == "light" then "1e333a" else "d9dce3";
        base04 = if cfg.polarity == "light" then "1e333a" else "d9dce3";
        base05 = if cfg.polarity == "light" then "363636" else "dadada";
        base06 = "e55e9c";
        base07 = "9a57a3";
        base08 = "ed5f5d";
        base09 = "f3ba4b";
        base0A = "f3ba4b";
        base0B = "79b757";
        base0C = "26a69a";
        base0D = "257cf7";
        base0E = "9a57a3";
        base0F = "e55e9c";
      };
    })

    # Fonts (fallback if stylix is disabled)
    (mkIf (cfg.targets.fonts.enable && !stylixCfg.enable) {
      stylix.fonts = with inputs.apple-fonts.packages.${pkgs.system}; {
        sansSerif = {
          package = mkForcable sf-pro;
          name = mkForcable "SF Pro";
        };
        serif = {
          package = mkForcable sf-pro;
          name = mkForcable "SF Pro";
        };
        monospace = {
          package = mkForcable sf-mono-nerd;
          name = mkForcable "SFMono Nerd Font";
        };
        emoji = {
          package = mkForcable pkgs.noto-fonts-emoji;
          name = mkForcable "Noto Color Emoji";
        };
        sizes = {
          applications = if whitesurCfg.smallerFont then 10 else 13;
          desktop = if whitesurCfg.smallerFont then 10 else 13;
          popups = if whitesurCfg.smallerFont then 10 else 13;
          terminal = if whitesurCfg.smallerFont then 10 else 13;
        };
      };
    })

    # Icons (fallback if stylix is disabled)
    (mkIf (cfg.targets.icons.enable && !stylixCfg.enable) {
      stylix.iconTheme = {
        enable = true;
        package = mkForcable pkgs.whitesur-icon-theme;
        light = mkForcable "WhiteSur-light";
        dark = mkForcable "WhiteSur-dark";
      };
    })

    # Cursor (fallback if stylix is disabled)
    (mkIf (cfg.targets.cursor.enable && !stylixCfg.enable) {
      stylix.cursor = {
        package = mkForcable pkgs.whitesur-cursors;
        name = mkForcable "WhiteSur-cursors";
        size = 24;
      };
    })

    # GTK Theme
    (mkIf cfg.targets.gtk.enable {
      gtk.theme = {
        name = lib.mkForce (mkForcable "WhiteSur-${toSentenceCase cfg.polarity}");
        package = lib.mkForce (mkForcable pkgs.whitesur-gtk-theme);
      };
      stylix.targets.gtk.flatpakSupport.enable = mkForcable false;
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
            name = lib.mkForce "WhiteSur-${toSentenceCase cfg.polarity}";
          };
          "org/gnome/desktop/wm/preferences" = {
            button-layout = "close,maximize,minimize:appmenu";
          };
          "org/gnome/shell/extensions/arcmenu" = {
            arc-menu-icon = 64;
            menu-layout = "GnomeOverview";
          };
          "org/gnome/shell/extensions/dash-to-dock" = {
            dash-max-icon-size = 64;
            dock-fixed = true;
            multi-monitur = true;
            scroll-action = "switch-workspace";
            show-show-apps-button = false;
          };
          # Additional WhiteSur GNOME customizations
          "org/gnome/shell/extensions/blur-my-shell" = {
            "panel-override-background" = true;
            "panel-background-opacity" = (builtins.fromJSON whitesurCfg.opacity) / 100.0;
            "dash-to-dock-blur" = true;
            "dash-to-dock-blur-on-overview" = true;
          };
          "org/gnome/desktop/interface" = {
            enable-hot-corners = true;
            show-battery-percentage = true;
          };
          "org/gnome/desktop/background" = {
            picture-uri = "file://${inputs.whitesur-wallpapers}/4k/WhiteSur-${cfg.polarity}.jpg";
            picture-uri-dark = "file://${inputs.whitesur-wallpapers}/4k/WhiteSur-${cfg.polarity}.jpg";
          };
        };
      })
      
      # KDE-specific theming
      (mkIf (lib.elem "kde" cfg.availableDesktops) {
        home.packages = with pkgs; mkForcable [
          whitesur-kde-theme
          whitesur-icon-theme
          whitesur-cursors
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

    # Wallpaper (fallback if stylix is disabled)
    (mkIf (cfg.targets.wallpaper.enable && !stylixCfg.enable) {
      stylix.image = mkForce "${inputs.whitesur-wallpapers}/4k/WhiteSur-${cfg.polarity}.jpg";
    })
  ]);
} 