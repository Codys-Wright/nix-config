# Hyprland Workflows - Composable workflow system
# Based on hyprland-profile-switcher architecture
{
  FTS,
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.wayland.windowManager.hyprland;

  # Value type for Hyprland settings (from hyprland-profile-switcher)
  valueType = with lib.types;
    nullOr (oneOf [
      bool
      int
      float
      str
      path
      (attrsOf valueType)
      (listOf valueType)
    ])
    // {
      name = "Hyprland configuration value";
    };
in {
  FTS.desktop._.environment._.hyprland._.workflows = {
    description = ''
      Hyprland workflow system with composable presets.
      
      Workflows allow switching between different Hyprland configurations on-the-fly.
      Uses composable presets for animations, shaders, and visual effects.
      
      Based on: https://github.com/heraldofsolace/hyprland-profile-switcher
    '';

    homeManager = {
      # Workflow options
      options.wayland.windowManager.hyprland.workflows = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Hyprland workflows system";
        };

        profiles = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Workflow profile name";
                example = "gaming";
              };

              animation = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Animation preset name (from HyDE)";
                example = "fast";
              };

              shader = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Shader preset name (from HyDE)";
                example = "blue-light-filter";
              };

              settings = lib.mkOption {
                type = valueType;
                default = {};
                description = "Additional Hyprland settings for this workflow";
                example = {
                  decoration = {
                    blur.enabled = true;
                    rounding = 10;
                  };
                  general = {
                    gaps_in = 5;
                    gaps_out = 10;
                  };
                };
              };
            };
          });
          default = [];
          description = "List of workflow profiles";
        };
      };

      # Configuration (when enabled)
      config = lib.mkIf cfg.workflows.enable {
        # Assertions
        assertions = [
          {
            assertion = let
              names = map (w: w.name) cfg.workflows.profiles;
              defaultCount = builtins.length (lib.filter (n: n == "default") names);
            in
              defaultCount == 1;
            message = "Workflows must have exactly one profile named 'default'";
          }
          {
            assertion = let
              names = map (w: w.name) cfg.workflows.profiles;
            in
              names == lib.unique names;
            message = "All workflow profile names must be unique";
          }
        ];

        # Install workflow switcher script
        home.packages = with pkgs; [
          # Will be added when we create the script
        ];

        # Source profile.conf in main Hyprland config
        wayland.windowManager.hyprland.settings.source = ["./profile.conf"];

        # Generate profile files
        xdg.configFile = builtins.listToAttrs (
          map (workflow: let
            # For now, just use the settings directly
            # We'll add preset composition in Phase 2 & 3
            allSettings = workflow.settings;
          in {
            name = "hypr/profiles/${workflow.name}.conf";
            value = {
              text = lib.hm.generators.toHyprconf {
                attrs = allSettings // {"$PROFILE_NAME" = workflow.name;};
              };
            };
          })
          cfg.workflows.profiles
        );

        # Initialize default profile symlink on first activation
        home.activation.initHyprlandWorkflow = lib.hm.dag.entryAfter ["writeBoundary"] ''
          profile_link="$HOME/.config/hypr/profile.conf"
          if [ ! -e "$profile_link" ]; then
            $DRY_RUN_CMD ln -sf "$HOME/.config/hypr/profiles/default.conf" "$profile_link"
          fi
        '';
      };
    };
  };
}
