# Wezterm terminal emulator aspect
{
  FTS, ... }:
{
  FTS.coding._.wezterm = {
    description = "Wezterm terminal emulator with custom configuration";

    homeManager = { config, pkgs, lib, ... }: {
      programs.wezterm = {
        enable = true;
        # Configuration is managed via dots.nix symlink to .config/wezterm/wezterm.lua
        # extraConfig can be added here if needed for programmatic configuration
      };

      # Additional wezterm utilities
      home.packages = with pkgs; [
        wezterm
      ];


    };
  };
}

