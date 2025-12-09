# GNOME macOS-inspired theme (Gnomintosh)
# Based on https://github.com/jothi-prasath/gnomintosh
# Uses stylix for unified theming (fonts and wallpaper)
{
  den,
  lib,
  FTS,
  inputs,
  ...
}:
let
  # Path to the gnomintosh theme directory
  gnomintoshDir = /home/cody/Documents/nix-reference/themes/gnomintosh;
in
{
  # Add required flake inputs
  flake-file.inputs.apple-fonts.url = "github:Lyndeno/apple-fonts.nix";
  flake-file.inputs.stylix.url = "github:danth/stylix";

  FTS.gnome-macos = {
    description = "GNOME macOS-inspired theme (Gnomintosh) with WhiteSur themes, icons, cursors, and fonts";

    nixos = { pkgs, ... }: {
      # Install required packages
      environment.systemPackages = with pkgs; [
        dconf
        gnome.gnome-tweaks
        gnomeExtensions.dash-to-dock
        gnomeExtensions.just-perfection
      ];
    };

    homeManager = { pkgs, config, lib, ... }:
    {
      # Import stylix module
      imports = [ inputs.stylix.homeModules.stylix ];

      # Enable dconf for GNOME configuration
      dconf.enable = true;

      # Install WhiteSur themes, icons, cursors, and required GNOME extensions
      home.packages = with pkgs; [
        whitesur-gtk-theme
        whitesur-icon-theme
        whitesur-cursor-theme
        gnomeExtensions.dash-to-dock
        gnomeExtensions.just-perfection
        # Install SF Pro Display font from apple-fonts flake
        inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-pro-display-regular
        noto-fonts-emoji
      ];

      # Configure stylix for fonts and wallpaper
      stylix = {
        enable = true;
        autoEnable = false; # Disable auto-enable to prevent conflicts
        
        # Use a dark base16 scheme to avoid auto-generation conflicts
        # Stylix will generate from wallpaper if base16Scheme is not set, which can cause conflicts
        base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";
        
        # Fonts - SF Pro Display
        fonts = with inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}; {
          sansSerif = {
            package = sf-pro-display-regular;
            name = "SF Pro Display";
          };
          serif = {
            package = sf-pro-display-regular;
            name = "SF Pro Display";
          };
          monospace = {
            package = sf-pro-display-regular;
            name = "SF Pro Display";
          };
          emoji = {
            package = pkgs.noto-fonts-emoji;
            name = "Noto Color Emoji";
          };
          sizes = {
            applications = 13;
            desktop = 13;
            popups = 13;
            terminal = 12;
          };
        };

        # Disable stylix GTK, cursor, and icon theming - we'll handle them manually with WhiteSur
        targets.gtk.enable = false;
        
        # Set wallpaper (for GNOME background, not for stylix color generation)
        image = "${gnomintoshDir}/wallpaper/monterey.png";
      };

      # Configure GTK theme manually with WhiteSur (stylix doesn't have WhiteSur built-in)
      gtk = {
        enable = true;
        theme = {
          name = "WhiteSur-Dark";
          package = pkgs.whitesur-gtk-theme;
        };
        iconTheme = {
          name = "WhiteSur-dark";
          package = pkgs.whitesur-icon-theme;
        };
        cursorTheme = {
          name = "WhiteSur-cursors";
          package = pkgs.whitesur-cursor-theme;
        };
        font.name = "SF Pro Display 13";

        gtk3.extraConfig = {
          Settings = ''
            gtk-font-name=SF Pro Display 13
            gtk-application-prefer-dark-theme=1
          '';
        };

        gtk4.extraConfig = {
          Settings = ''
            gtk-font-name=SF Pro Display 13
            gtk-application-prefer-dark-theme=1
          '';
        };
      };

      # Set GTK theme as session variable
      home.sessionVariables.GTK_THEME = "WhiteSur-Dark";

      # Copy wallpapers to Pictures/wallpapers directory
      home.file."Pictures/wallpapers/monterey.png".source = "${gnomintoshDir}/wallpaper/monterey.png";
      home.file."Pictures/wallpapers/blue-lotus1.png".source = "${gnomintoshDir}/wallpaper/blue-lotus1.png";
      home.file."Pictures/wallpapers/blue-lotus2.png".source = "${gnomintoshDir}/wallpaper/blue-lotus2.png";
      home.file."Pictures/wallpapers/smallsur.png".source = "${gnomintoshDir}/wallpaper/smallsur.png";
      home.file."Pictures/wallpapers/ventura.jpg".source = "${gnomintoshDir}/wallpaper/ventura.jpg";


      # Apply Gnomintosh dconf settings
      dconf.settings = {
        "org/gnome/desktop/interface" = {
          cursor-theme = "WhiteSur-cursors";
          document-font-name = "SF Pro Display 13";
          font-name = "SF Pro Display 13";
          gtk-theme = "WhiteSur-Dark";
          icon-theme = "WhiteSur-dark";
          monospace-font-name = "SF Pro Display 12";
        };

        "org/gnome/desktop/wm/preferences" = {
          button-layout = "close,minimize,maximize:";
          titlebar-font = "SF Pro Display 13";
        };

        "org/gnome/desktop/background" = {
          picture-uri = "file://${config.home.homeDirectory}/Pictures/wallpapers/monterey.png";
          picture-uri-dark = "file://${config.home.homeDirectory}/Pictures/wallpapers/monterey.png";
        };

        "org/gnome/shell" = {
          enabled-extensions = [
            pkgs.gnomeExtensions.dash-to-dock.extensionUuid
            pkgs.gnomeExtensions.just-perfection.extensionUuid
          ];
        };

        "org/gnome/shell/extensions/dash-to-dock" = {
          application-counter-overrides-notifications = true;
          apply-custom-theme = false;
          autohide = false;
          autohide-in-fullscreen = false;
          background-opacity = 0.45;
          click-action = "focus-minimize-or-previews";
          custom-background-color = false;
          custom-theme-shrink = true;
          customize-alphas = true;
          dash-max-icon-size = 43;
          disable-overview-on-startup = true;
          dock-fixed = true;
          dock-position = "BOTTOM";
          height-fraction = 1.0;
          hide-tooltip = false;
          hot-keys = false;
          intellihide = true;
          intellihide-mode = "MAXIMIZED_WINDOWS";
          max-alpha = 0.75;
          min-alpha = 0.4;
          multi-monitor = false;
          preferred-monitor = -2;
          preferred-monitor-by-connector = "eDP-1";
          preview-size-scale = 0.0;
          running-indicator-style = "DOTS";
          scroll-to-focused-application = true;
          show-apps-always-in-the-edge = true;
          show-apps-at-top = false;
          show-icons-emblems = true;
          show-icons-notifications-counter = true;
          show-running = true;
          show-show-apps-button = true;
          transparency-mode = "FIXED";
        };

        "org/gnome/shell/extensions/just-perfection" = {
          activities-button = false;
          alt-tab-icon-size = 0;
          alt-tab-small-icon-size = 0;
          alt-tab-window-preview-size = 0;
          clock-menu-position = 1;
          clock-menu-position-offset = 20;
          dash-icon-size = 0;
          looking-glass-width = 0;
          notification-banner-position = 2;
          panel-icon-size = 0;
          panel-size = 0;
          startup-status = 0;
          window-demands-attention-focus = true;
        };
      };
    };
  };
}
