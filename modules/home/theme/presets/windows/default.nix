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
  config = mkIf (cfg.preset == "windows") (mkMerge [
    # Colors
    (mkIf cfg.targets.colors.enable {
      stylix.override = mkForcable {
        base00 = if cfg.polarity == "light" then "ffffff" else "1e1e1e";
        base01 = if cfg.polarity == "light" then "f0f0f0" else "2d2d2d";
        base02 = if cfg.polarity == "light" then "e0e0e0" else "3c3c3c";
        base03 = if cfg.polarity == "light" then "d0d0d0" else "4b4b4b";
        base04 = if cfg.polarity == "light" then "c0c0c0" else "5a5a5a";
        base05 = if cfg.polarity == "light" then "000000" else "ffffff";
        base06 = "0078d4";
        base07 = "106ebe";
        base08 = "d13438";
        base09 = "ff8c00";
        base0A = "ffb900";
        base0B = "107c10";
        base0C = "008575";
        base0D = "0078d4";
        base0E = "9a0089";
        base0F = "e81123";
      };
    })

    # Fonts
    (mkIf cfg.targets.fonts.enable {
      stylix.fonts = {
        sansSerif = {
          package = mkForcable pkgs.segoe-ui;
          name = mkForcable "Segoe UI";
        };
        serif = {
          package = mkForcable pkgs.georgia;
          name = mkForcable "Georgia";
        };
        monospace = {
          package = mkForcable pkgs.consolas;
          name = mkForcable "Consolas";
        };
        emoji = {
          package = mkForcable pkgs.noto-fonts-emoji;
          name = mkForcable "Noto Color Emoji";
        };
        sizes = {
          applications = 12;
          desktop = 12;
          popups = 12;
          terminal = 12;
        };
      };
    })

    # Icons
    (mkIf cfg.targets.icons.enable {
      stylix.iconTheme = {
        enable = true;
        package = mkForcable pkgs.win11-icon-theme;
        light = mkForcable "Win11-light";
        dark = mkForcable "Win11-dark";
      };
    })

    # Cursor
    (mkIf cfg.targets.cursor.enable {
      stylix.cursor = {
        package = mkForcable pkgs.win11-cursors;
        name = mkForcable "Win11-cursors";
        size = 24;
      };
    })

    # GTK Theme
    (mkIf cfg.targets.gtk.enable {
      gtk.theme = {
        name = lib.mkForce (mkForcable "Win11-${toSentenceCase cfg.polarity}");
        package = lib.mkForce (mkForcable pkgs.win11-gtk-theme);
      };
    })

    # Shell/Desktop
    (mkIf cfg.targets.shell.enable {
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
          name = lib.mkForce "Win11-${toSentenceCase cfg.polarity}";
        };
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "close,minimize,maximize:appmenu";
        };
        "org/gnome/shell/extensions/arcmenu" = {
          arc-menu-icon = 64;
          menu-layout = "Windows";
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
  ]);
} 