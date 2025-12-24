# Hyprland Workflows - Composable workflow system
# Based on hyprland-profile-switcher architecture
{
  FTS,
  config,
  pkgs,
  lib,
  ...
}: let
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
      config,
      lib,
      ...
    }: let
      cfg = config.wayland.windowManager.hyprland;
    in {
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
                type = lib.types.str;
                default = "standard";
                description = "Animation preset name (from HyDE)";
                example = "fast";
              };

              shader = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
                description = "Shader preset name (from HyDE)";
                example = "blue-light-filter.frag";
              };

              decoration = lib.mkOption {
                type = lib.types.str;
                default = "elegant";
                description = "Decoration preset name";
                example = "glass";
              };

              layout = lib.mkOption {
                type = lib.types.str;
                default = "dwindle-default";
                description = "Layout preset name";
                example = "master-center";
              };

              cursor = lib.mkOption {
                type = lib.types.str;
                default = "default";
                description = "Cursor behavior preset name";
                example = "gaming";
              };

              window-rules = lib.mkOption {
                type = lib.types.str;
                default = "default";
                description = "Window rules preset name";
              };

              workspace-rules = lib.mkOption {
                type = lib.types.str;
                default = "default";
                description = "Workspace rules preset name";
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
          description = "List of workflow profiles (defaults loaded in config section)";
        };
      };

      # Configuration
      config = lib.mkMerge [
        # Load default workflow profiles from _profiles/ directory
        # (underscore prefix prevents import-tree from treating them as modules)
        {
          wayland.windowManager.hyprland.workflows.profiles = lib.mkDefault (
            let
              # Dynamically import all profile files from _profiles/ directory
              profilesDir = ./_profiles;
              profileFiles = builtins.attrNames (builtins.readDir profilesDir);
              loadedProfiles = map (f:
                let
                  imported = import (profilesDir + "/${f}");
                in
                  # Handle both plain attribute sets and functions
                  if builtins.isFunction imported
                  then imported {}
                  else imported
              ) (builtins.filter (lib.hasSuffix ".nix") profileFiles);
            in loadedProfiles
          );
        }
        
        # Always create a default profile (even when workflows are disabled)
        # This prevents the workflow switcher script from failing
        {
          # Dynamically install all presets and default profile
          xdg.configFile = let
            # Dynamically discover all animation preset files
            animationsDir = ../presets/animations;
            animationFiles = builtins.attrNames (builtins.readDir animationsDir);
            animationPresets = builtins.filter (name: lib.hasSuffix ".nix" name) animationFiles;

            # Dynamically discover all shader files
            shadersDir = ../presets/shaders/_shaderfiles;
            shaderFiles = builtins.attrNames (builtins.readDir shadersDir);
            shaderPresets = builtins.filter (name: lib.hasSuffix ".frag" name) shaderFiles;

            # Generate animation preset config files
            # Note: Beziers must be defined at root level, not inside animations block
            animationConfigs = builtins.listToAttrs (
              map (filename: let
                presetName = lib.removeSuffix ".nix" filename;
                presetModule = import (animationsDir + "/${filename}") {inherit FTS;};
                settings = presetModule.FTS.desktop._.environment._.hyprland._.presets._.animations._.${presetName}.settings;
                
                # Extract beziers and animations from nested structure
                animSettings = settings.animations or {};
                beziers = animSettings.bezier or [];
                animations = animSettings.animation or [];
                enabled = animSettings.enabled or true;
                
                # Generate Hyprland config with beziers at root level
                configText = ''
                  # Animation Preset: ${presetName}
                  
                  # Bezier curves (must be at root level)
                  ${lib.concatMapStringsSep "\n" (b: "bezier = ${b}") beziers}
                  
                  # Animation settings
                  animations {
                    enabled = ${if enabled then "true" else "false"}
                    
                    ${lib.concatMapStringsSep "\n  " (a: "animation = ${a}") animations}
                  }
                '';
              in {
                name = "hypr/presets/animations/${presetName}.conf";
                value = {
                  text = configText;
                };
              })
              animationPresets
            );

            # Generate shader file symlinks
            shaderConfigs = builtins.listToAttrs (
              map (filename: {
                name = "hypr/presets/shaders/${filename}";
                value = {
                  source = shadersDir + "/${filename}";
                };
              })
              shaderPresets
            );

            # Dynamically discover and generate decoration presets
            decorationsDir = ../presets/_decorations;
            decorationFiles = builtins.attrNames (builtins.readDir decorationsDir);
            decorationPresets = builtins.filter (name: lib.hasSuffix ".nix" name) decorationFiles;
            
            decorationConfigs = builtins.listToAttrs (
              map (filename: let
                presetData = import (decorationsDir + "/${filename}");
                presetName = presetData.name;
              in {
                name = "hypr/presets/decorations/${presetName}.conf";
                value = {
                  text = lib.hm.generators.toHyprconf {
                    attrs = presetData.settings;
                  };
                };
              })
              decorationPresets
            );

            # Dynamically discover and generate layout presets
            layoutsDir = ../presets/_layouts;
            layoutFiles = builtins.attrNames (builtins.readDir layoutsDir);
            layoutPresets = builtins.filter (name: lib.hasSuffix ".nix" name) layoutFiles;
            
            layoutConfigs = builtins.listToAttrs (
              map (filename: let
                presetData = import (layoutsDir + "/${filename}");
                presetName = presetData.name;
              in {
                name = "hypr/presets/layouts/${presetName}.conf";
                value = {
                  text = lib.hm.generators.toHyprconf {
                    attrs = presetData.settings;
                  };
                };
              })
              layoutPresets
            );

            # Dynamically discover and generate cursor presets
            cursorDir = ../presets/_cursor;
            cursorFiles = builtins.attrNames (builtins.readDir cursorDir);
            cursorPresets = builtins.filter (name: lib.hasSuffix ".nix" name) cursorFiles;
            
            cursorConfigs = builtins.listToAttrs (
              map (filename: let
                presetData = import (cursorDir + "/${filename}");
                presetName = presetData.name;
              in {
                name = "hypr/presets/cursor/${presetName}.conf";
                value = {
                  text = lib.hm.generators.toHyprconf {
                    attrs = presetData.settings;
                  };
                };
              })
              cursorPresets
            );

            # Dynamically discover and generate window-rules presets
            windowRulesDir = ../presets/_window-rules;
            windowRulesFiles = builtins.attrNames (builtins.readDir windowRulesDir);
            windowRulesPresets = builtins.filter (name: lib.hasSuffix ".nix" name) windowRulesFiles;
            
            windowRulesConfigs = builtins.listToAttrs (
              map (filename: let
                presetData = import (windowRulesDir + "/${filename}");
                presetName = presetData.name;
              in {
                name = "hypr/presets/window-rules/${presetName}.conf";
                value = {
                  text = lib.hm.generators.toHyprconf {
                    attrs = presetData.settings;
                  };
                };
              })
              windowRulesPresets
            );

            # Dynamically discover and generate workspace-rules presets
            workspaceRulesDir = ../presets/_workspace-rules;
            workspaceRulesFiles = builtins.attrNames (builtins.readDir workspaceRulesDir);
            workspaceRulesPresets = builtins.filter (name: lib.hasSuffix ".nix" name) workspaceRulesFiles;
            
            workspaceRulesConfigs = builtins.listToAttrs (
              map (filename: let
                presetData = import (workspaceRulesDir + "/${filename}");
                presetName = presetData.name;
              in {
                name = "hypr/presets/workspace-rules/${presetName}.conf";
                value = {
                  text = lib.hm.generators.toHyprconf {
                    attrs = presetData.settings;
                  };
                };
              })
              workspaceRulesPresets
            );

            # Default profile
            defaultProfile = {
              "hypr/profiles/default.conf" = lib.mkDefault {
                text = lib.hm.generators.toHyprconf {
                  attrs = {
                    "$PROFILE_NAME" = "default";
                    # Empty profile - uses main Hyprland settings
                  };
                };
              };
            };
          in
            lib.mkMerge [
              defaultProfile 
              animationConfigs 
              shaderConfigs
              decorationConfigs
              layoutConfigs
              cursorConfigs
              windowRulesConfigs
              workspaceRulesConfigs
            ];

          # Initialize default profile symlink on first activation
          home.activation.initHyprlandWorkflow = lib.hm.dag.entryAfter ["writeBoundary"] ''
            profile_link="$HOME/.config/hypr/profile.conf"
            runtime_anim="$HOME/.config/hypr/runtime-animation.conf"
            runtime_shader="$HOME/.config/hypr/runtime-shader.conf"
            runtime_decor="$HOME/.config/hypr/runtime-decoration.conf"
            runtime_layout="$HOME/.config/hypr/runtime-layout.conf"
            runtime_cursor="$HOME/.config/hypr/runtime-cursor.conf"
            runtime_wrules="$HOME/.config/hypr/runtime-window-rules.conf"
            runtime_wsrules="$HOME/.config/hypr/runtime-workspace-rules.conf"
            
            # Initialize profile link
            if [ ! -e "$profile_link" ]; then
              $DRY_RUN_CMD ln -sf "$HOME/.config/hypr/profiles/default.conf" "$profile_link"
            fi
            
            # Initialize runtime files with defaults
            if [ ! -f "$runtime_anim" ]; then
              echo "source = ./presets/animations/standard.conf" > "$runtime_anim"
            fi
            
            if [ ! -f "$runtime_shader" ]; then
              touch "$runtime_shader"
            fi
            
            if [ ! -f "$runtime_decor" ]; then
              echo "# Decoration preset - set via hyprland-manager" > "$runtime_decor"
              echo "# Will be populated on first workflow switch" >> "$runtime_decor"
            fi
            
            if [ ! -f "$runtime_layout" ]; then
              echo "# Layout preset - set via hyprland-manager" > "$runtime_layout"
              echo "# Will be populated on first workflow switch" >> "$runtime_layout"
            fi
            
            if [ ! -f "$runtime_cursor" ]; then
              echo "# Cursor preset - set via hyprland-manager" > "$runtime_cursor"
              echo "# Will be populated on first workflow switch" >> "$runtime_cursor"
            fi
            
            if [ ! -f "$runtime_wrules" ]; then
              echo "# Window rules preset - set via hyprland-manager" > "$runtime_wrules"
              echo "# Will be populated on first workflow switch" >> "$runtime_wrules"
            fi
            
            if [ ! -f "$runtime_wsrules" ]; then
              echo "# Workspace rules preset - set via hyprland-manager" > "$runtime_wsrules"
              echo "# Will be populated on first workflow switch" >> "$runtime_wsrules"
            fi
          '';
        }

        # Additional configuration when workflows are enabled
        (lib.mkIf cfg.workflows.enable {
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

          # Source profile and runtime files in main Hyprland config
          # Order matters: profile base → decoration → layout → animation → shader → cursor → rules
          wayland.windowManager.hyprland.settings.source = [
            "./profile.conf"                # Workflow base settings
            "./runtime-decoration.conf"     # Decoration preset (runtime modifiable)
            "./runtime-layout.conf"         # Layout preset (runtime modifiable)
            "./runtime-animation.conf"      # Animation preset (runtime modifiable)
            "./runtime-shader.conf"         # Shader effect (runtime modifiable)
            "./runtime-cursor.conf"         # Cursor behavior (runtime modifiable)
            "./runtime-window-rules.conf"   # Window rules (runtime modifiable)
            "./runtime-workspace-rules.conf" # Workspace rules (runtime modifiable)
          ];

          # Generate profile files (this will override the default profile created above)
          xdg.configFile = builtins.listToAttrs (
            map (workflow: let
              # Build metadata variables for all preset preferences
              # Only include SHADER if it's not null
              metadata = {
                "$PROFILE_NAME" = workflow.name;
                "$ANIMATION" = workflow.animation or "standard";
                "$DECORATION" = workflow.decoration or "elegant";
                "$LAYOUT" = workflow.layout or "dwindle-default";
                "$CURSOR" = workflow.cursor or "default";
                "$WINDOW_RULES" = workflow.window-rules or "default";
                "$WORKSPACE_RULES" = workflow.workspace-rules or "default";
              } // (if workflow.shader != null then {
                "$SHADER" = workflow.shader;
              } else {});
              
              # Merge settings with metadata (settings only, no preset sources)
              allSettings = workflow.settings // metadata;
            in {
              name = "hypr/profiles/${workflow.name}.conf";
              value = {
                text = lib.hm.generators.toHyprconf {
                  attrs = allSettings;
                };
              };
            })
            cfg.workflows.profiles
          );
        })
      ];
    }; # end of homeManager let-in
  };
}
