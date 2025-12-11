# MineGrub Theme for GRUB
# Minecraft-themed GRUB bootloader theme
{
  inputs,
  den,
  FTS,
  ...
}:
{
  # Add flake input for minegrub-theme
  flake-file.inputs.minegrub-theme = {
    url = "github:Lxtharia/minegrub-theme";
  };

  # MineGrub theme provider for GRUB
  FTS.grub._.themes._.minegrub = {
    description = "MineGrub theme for GRUB bootloader";

    nixos = {
      # Import the minegrub theme nixos module
      imports = [
        inputs.minegrub-theme.nixosModules.default
      ];

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
