# Minecraft gaming aspect
{
  FTS, ... }:
{
  FTS.minecraft = {
    description = "Minecraft with PrismLauncher";

    nixos = { config, pkgs, lib, ... }: {
      environment.systemPackages = with pkgs; [
        prismlauncher
      ];
    };
  };
}
