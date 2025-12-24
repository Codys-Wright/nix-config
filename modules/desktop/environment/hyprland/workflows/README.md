# Hyprland Workflows

HyDE-like workflow system for Hyprland using Nix and Home Manager.

Based on: [hyprland-profile-switcher](https://github.com/heraldofsolace/hyprland-profile-switcher)

## Overview

This module provides a composable workflow system for Hyprland that allows you to:
- Switch between different Hyprland configurations on-the-fly
- Compose workflows from preset animations and shaders
- Use all 19 animation presets from HyDE
- Use all 8 shader presets from HyDE
- Create custom workflows declaratively in Nix

## Architecture

### How It Works

1. **Workflow Profiles**: Defined declaratively in your Home Manager configuration
2. **Profile Files**: Generated in `~/.config/hypr/profiles/<name>.conf`
3. **Active Profile**: Symlinked as `~/.config/hypr/profile.conf`
4. **Sourced by Hyprland**: Main config sources `./profile.conf`
5. **Switch with Script**: Use `hyprland-workflow-switcher` to change workflows

### Directory Structure

```
workflows/
├── workflows.nix          # Main Home Manager module
└── README.md             # This file

presets/
├── animations/           # 19 animation presets from HyDE
│   ├── classic.nix
│   ├── diablo-1.nix
│   ├── diablo-2.nix
│   ├── disable.nix
│   ├── dynamic.nix
│   ├── end4.nix
│   ├── fast.nix
│   ├── high.nix
│   ├── ja.nix
│   ├── lime-frenzy.nix
│   ├── me-1.nix
│   ├── me-2.nix
│   ├── minimal-1.nix
│   ├── minimal-2.nix
│   ├── moving.nix
│   ├── optimized.nix
│   ├── standard.nix
│   ├── theme.nix
│   └── vertical.nix
└── shaders/             # 8 shader presets from HyDE
    ├── blue-light-filter.nix
    ├── color-vision.nix
    ├── grayscale.nix
    ├── invert-colors.nix
    ├── none.nix
    ├── oled-saver.nix
    ├── paper.nix
    └── vibrance.nix

scripts/
└── workflow-switcher.nix  # Workflow switching script
```

## Usage

### Enabling Workflows

In your Home Manager configuration:

```nix
wayland.windowManager.hyprland.workflows = {
  enable = true;
  
  profiles = [
    # Default workflow (required)
    {
      name = "default";
      animation = "optimized";  # Use HyDE's optimized animations
      shader = null;            # No shader
      settings = {
        # Additional Hyprland settings for this workflow
        decoration = {
          blur.enabled = true;
          rounding = 10;
        };
        general = {
          gaps_in = 3;
          gaps_out = 5;
        };
      };
    }
    
    # Gaming workflow
    {
      name = "gaming";
      animation = "disable";    # Disable animations for performance
      shader = null;
      settings = {
        decoration = {
          blur.enabled = false;
          rounding = 0;
        };
        general = {
          gaps_in = 0;
          gaps_out = 0;
        };
      };
    }
  ];
};
```

### Available Animation Presets

All from HyDE Project:

- `classic` - Classic mylinuxforwork style
- `diablo-1` - Vertical sliding animations
- `diablo-2` - Bouncy sliding variant
- `disable` - No animations (performance)
- `dynamic` - Dynamic responsive animations
- `end4` - End4's smooth style
- `fast` - Quick snappy (3s)
- `high` - High energy
- `ja` - Custom ja preset
- `lime-frenzy` - LimeFrenzy style
- `me-1` - mahaveergurjar style
- `me-2` - mahaveergurjar variant
- `minimal-1` - Minimal subtle
- `minimal-2` - Very minimal
- `moving` - Movement emphasis
- `optimized` - Highly optimized (recommended)
- `standard` - Standard balanced
- `theme` - Theme-based
- `vertical` - Vertical slide emphasis

### Available Shader Presets

All from HyDE Project:

- `none` - No shader (passthrough)
- `blue-light-filter` - Reduce blue light (3000K @ 90%)
- `color-vision` - Color vision deficiency compensation
- `grayscale` - Full grayscale
- `invert-colors` - Invert all colors
- `oled-saver` - OLED burn-in protection
- `paper` - E-ink/paper reading mode
- `vibrance` - Enhance color vibrance

### Switching Workflows

#### Using Keybinding

Press `$mod + W` to open walker menu and select a workflow.

#### Using Command Line

```bash
# Interactive selection with walker
hyprland-workflow-switcher --select walker

# Set specific workflow
hyprland-workflow-switcher --set gaming
hyprland-workflow-switcher --set coding

# Get current workflow
hyprland-workflow-switcher --get-current

# Reset to default
hyprland-workflow-switcher --reset
```

## Example Workflows

### Default (Balanced)
```nix
{
  name = "default";
  animation = "optimized";
  shader = null;
  settings = {
    decoration = {
      blur.enabled = true;
      active_opacity = 0.9;
      inactive_opacity = 0.8;
      rounding = 10;
    };
    general = {
      gaps_in = 3;
      gaps_out = 5;
      layout = "master";
    };
  };
}
```

### Gaming (Maximum Performance)
```nix
{
  name = "gaming";
  animation = "disable";
  shader = null;
  settings = {
    decoration = {
      blur.enabled = false;
      shadow.enabled = false;
      active_opacity = 1.0;
      inactive_opacity = 1.0;
      rounding = 0;
    };
    general = {
      gaps_in = 0;
      gaps_out = 0;
    };
  };
}
```

### Coding (Focus & Readability)
```nix
{
  name = "coding";
  animation = "fast";
  shader = "blue-light-filter";  # Optional: for evening coding
  settings = {
    decoration = {
      blur.enabled = false;
      active_opacity = 0.95;
      inactive_opacity = 0.85;
      rounding = 5;
    };
    general = {
      gaps_in = 5;
      gaps_out = 8;
      border_size = 2;
      layout = "master";
    };
  };
}
```

### Music Production (Low Latency)
```nix
{
  name = "music-production";
  animation = "minimal-1";
  shader = null;
  settings = {
    decoration = {
      blur.enabled = false;
      active_opacity = 1.0;
      inactive_opacity = 0.9;
      rounding = 8;
    };
    general = {
      gaps_in = 4;
      gaps_out = 6;
    };
    misc.vfr = false;  # Fixed FPS for audio sync
  };
}
```

## Important Notes

### Settings Priority

Settings defined in `wayland.windowManager.hyprland.settings` will **override** workflow-specific settings.

To allow workflows to control a setting:
1. Remove it from `config/settings.nix`
2. Define it in each workflow's `settings` attribute

### Requirements

- One workflow must be named `default`
- All workflow names must be unique
- Hyprland will auto-reload when switching workflows

### First Load

On first load after enabling workflows, you may see an error about missing `profile.conf`. This is expected. Simply:
1. Use `hyprland-workflow-switcher --select walker` to choose a profile
2. Reload Hyprland
3. Error will be gone

## Credits

- Animation presets: [HyDE Project](https://github.com/HyDE-Project/HyDE)
- Shader presets: [HyDE Project](https://github.com/HyDE-Project/HyDE)
- Architecture: [hyprland-profile-switcher](https://github.com/heraldofsolace/hyprland-profile-switcher)
- Implementation: Adapted for FTS/aspect-based Nix configuration
