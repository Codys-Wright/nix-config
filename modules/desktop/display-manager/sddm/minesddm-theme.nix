# MineSDDM Theme for SDDM
# Minecraft-themed SDDM display manager theme
{
  inputs,
  den,
  FTS,
  pkgs,
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

      environment.systemPackages = with pkgs; [
        libsForQt5.layer-shell-qt
      ];

      services.displayManager.sddm = {
        enable = true;
        theme = "minesddm";
      };
    };
  };
}
