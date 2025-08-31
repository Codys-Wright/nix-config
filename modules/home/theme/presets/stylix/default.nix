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
  config = mkIf (cfg.preset == "stylix") (mkMerge [
    # Colors - Use default Gruvbox
    (mkIf cfg.targets.colors.enable {
      stylix = {
        base16Scheme = mkForcable "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";
      };
    })

    # Fonts - Use default fonts
    (mkIf cfg.targets.fonts.enable {
      stylix.fonts = {
        monospace = {
          package = mkForcable pkgs.nerd-fonts.jetbrains-mono;
          name = mkForcable "JetBrainsMono Nerd Font Mono";
        };
        sansSerif = {
          package = mkForcable inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
          name = mkForcable "SFProDisplay Nerd Font";
        };
        serif = {
          package = mkForcable inputs.apple-fonts.packages.${pkgs.system}.sf-pro-nerd;
          name = mkForcable "SFProDisplay Nerd Font";
        };
        emoji = {
          package = mkForcable pkgs.noto-fonts-emoji;
          name = mkForcable "Noto Color Emoji";
        };
        sizes = {
          applications = 13;
          desktop = 13;
          popups = 13;
          terminal = 13;
        };
      };
    })

    # Icons - Use default icons
    (mkIf cfg.targets.icons.enable {
      stylix.iconTheme = {
        enable = true;
        package = mkForcable pkgs.papirus-icon-theme;
        light = mkForcable "Papirus-Light";
        dark = mkForcable "Papirus-Dark";
      };
    })

    # Cursor - Use default cursor
    (mkIf cfg.targets.cursor.enable {
      stylix.cursor = {
        package = mkForcable pkgs.bibata-cursors;
        name = mkForcable "Bibata-Modern-Ice";
        size = 24;
      };
    })

    # Wallpaper - Use default image
    (mkIf cfg.targets.wallpaper.enable {
      stylix.image = mkForcable ../../../wallpapers/sports.png;
    })

    # Desktop Environment Theming
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
            name = "Gruvbox-Dark";
          };
          "org/gnome/desktop/wm/preferences" = {
            button-layout = "close,minimize,maximize:appmenu";
          };
        };
      })

      # KDE-specific theming
      (mkIf (lib.elem "kde" cfg.availableDesktops) {
        home.packages = with pkgs; mkForcable [
          materia-kde-theme
          papirus-icon-theme
          bibata-cursors
        ];
        qt = {
          enable = true;
          platformTheme.name = "kde";
          style.name = "breeze";
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
      })
    ]))
  ]);
}
