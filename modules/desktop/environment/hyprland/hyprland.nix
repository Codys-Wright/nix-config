# Hyprland environment aggregator
{FTS, ...}: {
  FTS.desktop._.environment._.hyprland = {
    description = "Hyprland desktop environment, including core and keybinds";

    includes = [
      FTS.desktop._.environment._.hyprland._.core
    ];

    nixos = {
      # Enable Hyprland
      programs.hyprland = {
        enable = true;
      };
    };
  };
}
