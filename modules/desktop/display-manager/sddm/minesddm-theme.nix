# MineSDDM Theme for SDDM
# Minecraft-themed SDDM display manager theme
{
  inputs,
  den,
  FTS,
  ...
}:
{
  # Add flake input for minesddm theme
  flake-file.inputs.minesddm = {
    url = "github:Davi-S/sddm-theme-minesddm";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # MineSDDM theme aspect
  FTS.minesddm = {
    description = "SDDM display manager with MineSDDM theme";

    nixos = {
      # Import the minesddm theme nixos module
      imports = [
        inputs.minesddm.nixosModules.default
      ];

      services.displayManager.sddm = {
        enable = true;
        theme = "minesddm";
      };
    };
  };
}
