{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) mkIf mkMerge toSentenceCase;
  inherit (config.lib.themix) mkForcable;
  cfg = config.themix;
in {
  imports = [
    ./common.nix
  ];
  
  config = mkIf cfg.enable (mkMerge [
    # WhiteSur theme
    (mkIf cfg.themes.whitesur.enable (mkMerge [
      (mkIf cfg.targets.colors.enable {
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

      (mkIf cfg.targets.fonts.enable {
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
        };
      })

      (mkIf cfg.targets.icons.enable {
        stylix.iconTheme = {
          package = mkForcable pkgs.whitesur-icon-theme;
          dark = mkForcable "WhiteSur-${cfg.polarity}";
        };
      })

      (mkIf cfg.targets.cursor.enable {
        stylix.cursor = {
          package = mkForcable pkgs.whitesur-cursors;
          name = mkForcable "WhiteSur-cursors";
        };
      })

      (mkIf cfg.targets.gtk.enable {
        gtk.theme = {
          package = mkForcable pkgs.whitesur-gtk-theme;
          name = mkForcable "WhiteSur-${toSentenceCase cfg.polarity}";
        };
        stylix.targets.gtk.flatpakSupport.enable = mkForcable false;
      })

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
            name = "WhiteSur-${toSentenceCase cfg.polarity}";
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
        };
      })
    ]))
  ]);
} 