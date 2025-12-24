/*
Hyprland environment aggregator - Main entry point
*/
{
  FTS,
  lib,
  pkgs,
  ...
}: {
  FTS.desktop._.environment._.hyprland = {
    description = ''
      Hyprland desktop environment with modular configuration.
    '';

    nixos = {pkgs, ...}: {
      # Enable Hyprland at system level
      programs.hyprland = {
        enable = true;
      };

      # Install Hyprland ecosystem packages
      environment.systemPackages = with pkgs; [
        hyprpicker
        hyprcursor
        hypridle
        hyprpaper
        hyprsunset
      ];
    };

    homeManager = {...}: {
      # Enable Hyprland window manager
      wayland.windowManager.hyprland = {
        enable = true;
        xwayland.enable = true;

        # Enable workflow system (profiles loaded from workflows module)
        workflows.enable = true;
      };
    };

    # Include all sub-aspects by default
    includes = [
      # Core configuration aspects
      FTS.desktop._.environment._.hyprland._.config._.binds
      FTS.desktop._.environment._.hyprland._.config._.monitors
      FTS.desktop._.environment._.hyprland._.config._.settings
      FTS.desktop._.environment._.hyprland._.config._.rules

      # Workflow system
      FTS.desktop._.environment._.hyprland._.workflows

      # App aspects
      FTS.desktop._.environment._.hyprland._.apps._.walker

      # Plugin aspects
      FTS.desktop._.environment._.hyprland._.plugins._.dunst
      FTS.desktop._.environment._.hyprland._.plugins._.hyprcursor
      FTS.desktop._.environment._.hyprland._.plugins._.hypridle
      FTS.desktop._.environment._.hyprland._.plugins._.hyprpaper
      FTS.desktop._.environment._.hyprland._.plugins._.hyprlock
      FTS.desktop._.environment._.hyprland._.plugins._.pyprland

      # Script aspects
      FTS.desktop._.environment._.hyprland._.scripts._.run-or-raise
      FTS.desktop._.environment._.hyprland._.scripts._.workflow-switcher
      FTS.desktop._.environment._.hyprland._.scripts._.hyprland-manager
    ];
  };
}
