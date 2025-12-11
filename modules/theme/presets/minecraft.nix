# Minecraft Theme Preset
# Applies Minecraft-inspired theming across the entire desktop environment
{
  FTS,
  lib,
  ...
}:
{
  FTS.theme._.presets._.minecraft = {
    description = ''
      Minecraft theme preset - Applies Minecraft-inspired theming system-wide.
      
      This preset configures FTS aspects with Minecraft theme selections:
      - GRUB bootloader → minegrub theme
      - SDDM display manager → minecraft theme (if implemented)
      - Future: GNOME, KDE, Qt, GTK theming
      
      Usage:
        (<FTS/theme/presets/minecraft> { })
      
      The theme preset just passes theme parameters to FTS modules using lib.mkDefault.
      You can still override by explicitly configuring the aspects yourself.
    '';

    includes = [
      # Configure desktop with minegrub bootloader theme
      (FTS.desktop {
        bootloader.grub.theme = lib.mkDefault "minegrub";
      })
      
      # Future: Configure other themed components
      # (FTS.desktop {
      #   displayManager.sddm.theme = lib.mkDefault "minecraft";
      # })
    ];
  };
}

