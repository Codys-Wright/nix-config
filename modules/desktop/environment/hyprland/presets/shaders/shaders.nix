# Hyprland Shader Presets
# All shaders from HyDE Project
# Shader files are stored in ./_shaderfiles/ directory
{
  FTS,
  pkgs,
  ...
}: {
  FTS.desktop._.environment._.hyprland._.presets._.shaders = {
    description = "Hyprland screen shader presets from HyDE Project";

    # Helper function to create shader preset from file
    mkShader = name: file: description: {
      inherit description;
      settings = {
        decoration = {
          screen_shader = "${./_shaderfiles + "/${file}"}";
        };
      };
    };

    # All shader presets
    presets = {
      # Disable/None - Passthrough shader (no effect)
      none = {
        description = "No shader (passthrough)";
        settings = {
          decoration = {
            screen_shader = "${./_shaderfiles/disable.frag}";
          };
        };
      };

      # Blue Light Filter - Reduces blue light for evening use
      blue-light-filter = {
        description = "Blue light filter (3000K @ 90% intensity)";
        settings = {
          decoration = {
            screen_shader = "${./_shaderfiles/blue-light-filter.frag}";
          };
        };
      };

      # Color Vision - Color vision deficiency compensation
      color-vision = {
        description = "Color vision deficiency shader (accessibility)";
        settings = {
          decoration = {
            screen_shader = "${./_shaderfiles/color-vision.frag}";
          };
        };
      };

      # Grayscale - Full grayscale conversion
      grayscale = {
        description = "Grayscale shader (HDTV luminosity)";
        settings = {
          decoration = {
            screen_shader = "${./_shaderfiles/grayscale.frag}";
          };
        };
      };

      # Invert Colors - Inverts all colors
      invert-colors = {
        description = "Invert colors shader (accessibility)";
        settings = {
          decoration = {
            screen_shader = "${./_shaderfiles/invert-colors.frag}";
          };
        };
      };

      # OLED Saver - OLED burn-in protection
      oled-saver = {
        description = "OLED burn-in protection (10s swap interval)";
        settings = {
          decoration = {
            screen_shader = "${./_shaderfiles/oled-saver.frag}";
          };
        };
      };

      # Paper - E-ink/paper reading mode
      paper = {
        description = "Paper/e-ink effect (reading mode)";
        settings = {
          decoration = {
            screen_shader = "${./_shaderfiles/paper.frag}";
          };
        };
      };

      # Vibrance - Enhances color vibrance
      vibrance = {
        description = "Vibrance shader (enhances colors, protects skin tones)";
        settings = {
          decoration = {
            screen_shader = "${./_shaderfiles/vibrance.frag}";
          };
        };
      };

      # Wallbash - HyDE's wallpaper color integration
      wallbash = {
        description = "Wallbash shader (HyDE wallpaper color integration)";
        settings = {
          decoration = {
            screen_shader = "${./_shaderfiles/wallbash.frag}";
          };
        };
      };

      # Custom - User customizable shader
      custom = {
        description = "Custom shader (modify custom.frag)";
        settings = {
          decoration = {
            screen_shader = "${./_shaderfiles/custom.frag}";
          };
        };
      };
    };
  };
}
