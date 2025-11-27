# MineGrub Theme for GRUB
# Minecraft-themed GRUB bootloader theme
{
  inputs,
  den,
  ...
}:
{
  # Add flake input for minegrub-theme
  flake-file.inputs.minegrub-theme = {
    url = "github:Lxtharia/minegrub-theme";
  };

  # MineGrub theme aspect
  den.aspects.grub.minegrub = {
    description = "GRUB bootloader with MineGrub theme";

    nixos = {
      boot.loader.grub = {
        enable = true;
        minegrub-theme = {
          enable = true;
          splash = "100% Flakes!";
          background = "background_options/1.8  - [Classic Minecraft].png";
          boot-options-count = 4;
        };
      };
    };
  };
}
