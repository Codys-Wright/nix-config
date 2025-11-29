# MineGrub World Selection Theme for GRUB
# Minecraft world selection themed GRUB bootloader theme
{
  inputs,
  den,
  FTS,
  ...
}:
{
  # Add flake input for minegrub-world-sel-theme
  flake-file.inputs.minegrub-world-sel-theme = {
    url = "github:Lxtharia/minegrub-world-sel-theme";
  };

  # MineGrub World Selection theme aspect
  FTS.grub.minegrub-world-sel = {
    description = "GRUB bootloader with MineGrub World Selection theme";

    nixos = {
      boot.loader.grub = {
        enable = true;
        minegrub-world-sel = {
          enable = true;
          customIcons = [{
            name = "nixos";
            lineTop = "NixOS (23/11/2023, 23:03)";
            lineBottom = "Survival Mode, No Cheats, Version: 23.11";
            # Icon: you can use an icon from the remote repo, or load from a local file
            imgName = "nixos";
            # customImg = builtins.path {
            #   path = ./nixos-logo.png;
            #   name = "nixos-img";
            # };
          }];
        };
      };
    };
  };
}
