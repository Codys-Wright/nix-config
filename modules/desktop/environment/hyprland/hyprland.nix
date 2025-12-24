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
      
      Usage:
        (<FTS/desktop/environment/hyprland> { })
      
      Direct access to sub-aspects:
        Config aspects:
          (<FTS/desktop/environment/hyprland/config/binds> { })
          (<FTS/desktop/environment/hyprland/config/monitors> { })
          (<FTS/desktop/environment/hyprland/config/settings> { })
          (<FTS/desktop/environment/hyprland/config/rules> { })
        
        Workflow system:
          (<FTS/desktop/environment/hyprland/workflows> { })
        
        Plugin aspects:
          (<FTS/desktop/environment/hyprland/plugins/hyprcursor> { })
          (<FTS/desktop/environment/hyprland/plugins/hypridle> { })
          (<FTS/desktop/environment/hyprland/plugins/hyprpaper> { })
          (<FTS/desktop/environment/hyprland/plugins/hyprlock> { })
          (<FTS/desktop/environment/hyprland/plugins/pyprland> { })
        
        Script aspects:
          (<FTS/desktop/environment/hyprland/scripts/run-or-raise> { })
          (<FTS/desktop/environment/hyprland/scripts/workflow-switcher> { })
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

    homeManager = {
      # Enable Hyprland window manager
      wayland.windowManager.hyprland = {
        enable = true;
        xwayland.enable = true;
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

      # Plugin aspects
      FTS.desktop._.environment._.hyprland._.plugins._.hyprcursor
      FTS.desktop._.environment._.hyprland._.plugins._.hypridle
      FTS.desktop._.environment._.hyprland._.plugins._.hyprpaper
      FTS.desktop._.environment._.hyprland._.plugins._.hyprlock
      FTS.desktop._.environment._.hyprland._.plugins._.pyprland

      # Script aspects
      FTS.desktop._.environment._.hyprland._.scripts._.run-or-raise
      FTS.desktop._.environment._.hyprland._.scripts._.workflow-switcher
    ];
  };
}
