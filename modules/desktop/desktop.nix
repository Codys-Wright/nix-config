# Desktop Module - Main orchestrator for desktop environments and keybinds
# This module ties together the keybind abstractions and desktop environment implementations
{ ... }:
{
  den.aspects.desktop = {
    description = "Main desktop environment orchestrator with keybind abstractions";

    homeManager = { config, lib, ... }: {
      # Import all desktop abstractions and environments
      imports = [
        ./abstractions/keybinds.nix
        ./environments/hyprland/keybinds.nix
      ];

      # Desktop environment selection
      options.desktop.environment = with lib.types; {
        enable = lib.mkOption {
          type = bool;
          default = false;
          description = "Enable desktop environment";
        };

        type = lib.mkOption {
          type = enum [ "hyprland" "gnome" "kde" ];
          default = "hyprland";
          description = "Desktop environment to use";
        };
      };

      # Configuration based on selected environment
      config = lib.mkIf config.desktop.environment.enable {
        # Enable the keybind abstractions
        assertions = [{
          assertion = config.desktop.environment.type != null;
          message = "Desktop environment type must be specified";
        }];

        # Environment-specific includes
        den.aspects = lib.mkMerge [
          (lib.mkIf (config.desktop.environment.type == "hyprland") {
            hyprland-keybinds.enable = true;
          })
          # Future desktop environments can be added here
          # (lib.mkIf (config.desktop.environment.type == "gnome") {
          #   gnome-keybinds.enable = true;
          # })
        ];
      };
    };
  };
}
