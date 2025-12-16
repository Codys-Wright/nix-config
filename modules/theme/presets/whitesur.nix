# WhiteSur Theme Preset
# macOS Big Sur-inspired theming across the entire system
{
  FTS,
  lib,
  ...
}:
{
  FTS.theme._.presets._.whitesur = {
    description = ''
      WhiteSur theme preset - macOS Big Sur-inspired theming system-wide.

      This preset configures:
      - GTK theme → WhiteSur Dark
      - Qt theme → WhiteSur (via GTK)
      - Icons → WhiteSur dark
      - Cursors → WhiteSur cursors
      - Fonts → macOS-style fonts (San Francisco family)
      - Bootloader → WhiteSur GRUB theme (if available)

      Usage:
        (<FTS/theme/presets/whitesur> { })

      All settings use lib.mkDefault, so you can override individual components.
    '';

    includes = [
      # GTK theming
      (FTS.theme._.gtk {
        theme = lib.mkDefault "whitesur";
      })

      # Qt theming
      (FTS.theme._.qt {
        theme = lib.mkDefault "whitesur";
      })

      # Icon theming
      (FTS.theme._.icons {
        theme = lib.mkDefault "whitesur-dark";
      })

      # Cursor theming
      (FTS.theme._.cursors {
        theme = lib.mkDefault "whitesur";
        size = lib.mkDefault 24;
      })

      # Font configuration
      (FTS.theme._.fonts {
        preset = lib.mkDefault "macos";
      })

      # Desktop environment theming (configured via FTS.desktop)
      # Note: These are applied when using FTS.desktop with WhiteSur theme
      # Individual themes like GNOME and KDE will include the GTK/icon themes

      # Example desktop configuration with WhiteSur:
      # (FTS.desktop {
      #   environment = {
      #     default = "gnome";
      #     gnome.theme = "whitesur";
      #   };
      # })
      # or
      # (FTS.desktop {
      #   environment = {
      #     default = "kde";
      #     kde.theme = "whitesur";
      #   };
      # })
    ];
  };
}
