# Hyprland Shader Presets

All shaders from the [HyDE Project](https://github.com/HyDE-Project/HyDE).

## Structure

- `shaders.nix` - Main module that exports all shader presets
- `_shaderfiles/` - Directory containing actual GLSL shader files

## Available Shaders

### none (disable.frag)
Passthrough shader - no effect. Use this to disable shaders.

### blue-light-filter (blue-light-filter.frag)
Reduces blue light for evening use. Default: 3000K @ 90% intensity.

**Customizable parameters:**
- `BLUE_LIGHT_FILTER_TEMPERATURE` - Color temperature in Kelvin (1000-40000)
- `BLUE_LIGHT_FILTER_INTENSITY` - Filter intensity (0.0-1.0)

### color-vision (color-vision.frag)
Color vision deficiency simulation and compensation for accessibility.

**Customizable parameters:**
- `COLOR_VISION_MODE` - 0: Normal, 1: Protanopia, 2: Deuteranopia, 3: Tritanopia
- `COLOR_VISION_INTENSITY` - -1.0: Daltonization, 0.0: No effect, 1.0: CVD simulation

### grayscale (grayscale.frag)
Converts screen to grayscale using HDTV luminosity standards.

**Customizable parameters:**
- `GRAYSCALE_LUMINOSITY` - Luminosity calculation type
- Multiple other luminosity modes available

### invert-colors (invert-colors.frag)
Inverts all colors. Useful for accessibility or dark mode emulation.

**Customizable parameters:**
- `INVERT_COLORS_INTENSITY` - Inversion intensity (0.0-1.0)

**Note:** May have quirks with animations and blur effects.

### oled-saver (oled-saver.frag)
OLED burn-in protection using animated checker pattern.

**Customizable parameters:**
- `OLED_MONITOR` - Monitor index (-1 for all)
- `OLED_FILL_COLOR` - Fill color for checker pattern
- `OLED_SWAP_INTERVAL` - Swap interval in seconds (default: 10.0)
- `OLED_PIXEL_SIZE` - Checker square size (default: 1.0)

### paper (paper.frag)
E-ink/paper reading mode with grain texture.

**Customizable parameters:**
- `PAPER_GRAYSCALE` - Grayscale strength (0.0-1.0)
- `PAPER_CONTRAST` - Contrast adjustment (default: 1.0)
- `PAPER_BRIGHTNESS` - Brightness adjustment (default: 0.0)
- `PAPER_SEPIA` - Sepia intensity (0.0-1.0)
- `PAPER_GRAIN` - Paper grain strength (default: 0.7)

### vibrance (vibrance.frag)
Enhances color vibrance while preserving skin tones.

**Customizable parameters:**
- `VIBRANCE_INTENSITY` - Vibrance level (-1.0 to 1.0)
- `SHADER_VIBRANCE_SKIN_TONE_PROTECTION` - Skin tone protection (0.0-1.0, default: 0.75)

### wallbash (wallbash.frag)
HyDE's wallpaper color integration shader.

### custom (custom.frag)
User-customizable shader template. Modify this file for your own effects.

## Adding New Shaders

To add a new shader:

1. Add the `.frag` file to `_shaderfiles/` directory
2. Update `shaders.nix` to add a new preset entry:

```nix
new-shader = {
  description = "Description of new shader";
  settings = {
    decoration = {
      screen_shader = "${./_shaderfiles/new-shader.frag}";
    };
  };
};
```

3. Rebuild your system

## Customizing Shader Parameters

To customize shader parameters, create a `.inc` file in your `~/.config/hypr/shaders/` directory.

For example, to customize blue light filter:

```glsl
// File: ~/.config/hypr/shaders/blue-light-filter.inc
#define BLUE_LIGHT_FILTER_TEMPERATURE 4000.0
#define BLUE_LIGHT_FILTER_INTENSITY 0.7
```

The shader will automatically include this file if it exists.

## Shader Format

All shaders are GLSL ES 3.0. Basic structure:

```glsl
#version 300 es
precision highp float;

in vec2 v_texcoord;
out vec4 fragColor;
uniform sampler2D tex;

// Optional customizable parameters
#ifndef MY_PARAMETER
    #define MY_PARAMETER default_value
#endif

void main() {
    vec4 pixColor = texture(tex, v_texcoord);
    
    // Shader logic here
    
    fragColor = pixColor;
}
```

## Credits

All shaders from the [HyDE Project](https://github.com/HyDE-Project/HyDE).

Individual shader credits are in the shader files themselves.
