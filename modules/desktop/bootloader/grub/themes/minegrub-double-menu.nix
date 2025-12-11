# MineGrub Double Menu Theme for GRUB
# Combines both minegrub-theme (main menu) and minegrub-world-sel-theme (world selection)
# Creates a two-stage boot menu experience like Minecraft
{
  inputs,
  den,
  FTS,
  ...
}:
{
  # MineGrub double menu theme provider for GRUB
  FTS.grub._.themes._.minegrub-double-menu = {
    description = "MineGrub double menu theme (main menu + world selection) for GRUB bootloader";

    includes = [
      FTS.grub._.themes._.minegrub
      FTS.grub._.themes._.minegrub-world-sel
    ];

    nixos = {
      # Ensure GRUB is enabled
      boot.loader.grub.enable = true;

      # Configure both themes
      # Main menu uses minegrub-theme (configured via minegrub aspect)
      # World selection uses minegrub-world-sel-theme (configured via minegrub-world-sel aspect)
      boot.loader.grub.minegrub-theme.enable = true;
      boot.loader.grub.minegrub-world-sel.enable = true;

      # Configure GRUB for double menu
      boot.loader.grub = {
        # Set timeout style to menu (required for double menu)
        timeoutStyle = "menu";
        
        # Use world-selection theme for the main grub.cfg
        # The main menu theme is set in mainmenu.cfg
        theme = "minegrub-world-selection";
      };
    };
  };
}
