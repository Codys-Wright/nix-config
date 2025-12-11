# Cody Theme Preset
# WhiteSur macOS-style theme with Minecraft bootloader
# Custom theme combining the best of both worlds!
{
  FTS,
  lib,
  ...
}:
{
  FTS.theme._.presets._.cody = {
    description = ''
      Cody's custom theme preset - The best of both worlds!
      
      This preset configures:
      - GTK theme → WhiteSur Dark (macOS style)
      - Qt theme → WhiteSur (macOS style)
      - Icons → WhiteSur dark
      - Cursors → WhiteSur cursors
      - Fonts → macOS-style fonts (San Francisco family)
      - Bootloader → MineGrub (Minecraft theme)
      
      Usage:
        (<FTS/theme> { default = "cody"; })
      
      All settings use lib.mkDefault, so you can override individual components.
    '';

    includes = [
      # GTK theming (WhiteSur)
      (FTS.theme._.gtk { 
        theme = lib.mkDefault "whitesur";
      })
      
      # Qt theming (WhiteSur)
      (FTS.theme._.qt { 
        theme = lib.mkDefault "whitesur";
      })
      
      # Icon theming (WhiteSur)
      (FTS.theme._.icons { 
        theme = lib.mkDefault "whitesur-dark";
      })
      
      # Cursor theming (WhiteSur)
      (FTS.theme._.cursors { 
        theme = lib.mkDefault "whitesur";
        size = lib.mkDefault 24;
      })
      
      # Font configuration (macOS-style)
      (FTS.theme._.fonts { 
        preset = lib.mkDefault "macos";
      })
      
      # Bootloader theming (Minecraft!)
      # Uses mkDefault so it won't override if system already set it
      (FTS.desktop {
        bootloader.grub.theme = lib.mkDefault "minegrub";
      })
      
      # Desktop environment theming
      # (FTS.desktop {
      #   environment.kde.theme = lib.mkDefault "whitesur";
      # })
    ];
  };
}

