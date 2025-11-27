# MineSDDM Theme for SDDM
# Minecraft-themed SDDM display manager theme
{
  inputs,
  den,
  ...
}:
{
  # Add flake input for minesddm theme
  flake-file.inputs.minesddm = {
    url = "github:Davi-S/sddm-theme-minesddm";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # MineSDDM theme aspect
  den.aspects.sddm.minesddm = {
    description = "SDDM display manager with MineSDDM theme";

    nixos = {
      services.displayManager.sddm = {
        enable = true;
        theme = "minesddm";
      };
    };
  };
}
