# Minecraft-themed boot and display manager aspect
# Combines GRUB with MineGrub double menu theme and SDDM with MineSDDM theme
# Provides a complete Minecraft-themed boot experience
{
  inputs,
  den,
  lib,
  FTS,
  ...
}:
{
  FTS.minecraft = {
    description = "Minecraft-themed boot and display manager configuration - GRUB double menu + SDDM theme";

    nixos = {
      # Import the theme modules
      imports = [
        inputs.minegrub-theme.nixosModules.default
        # TODO: Fix minesddm theme - it requires libsForQt5.layer-shell-qt which is missing
        # inputs.minesddm.nixosModules.default
      ];

      # GRUB configuration
      boot.loader.grub = {
        enable = true;
        minegrub-theme = {
          enable = true;
          splash = "100% Flakes!";
          background = "background_options/1.8  - [Classic Minecraft].png";
          boot-options-count = 4;
        };
      };

      # SDDM configuration (minesddm theme disabled until dependency issue is fixed)
      # services.displayManager.sddm = {
      #   enable = true;
      #   theme = "minesddm";
      # };
    };
  };
}
