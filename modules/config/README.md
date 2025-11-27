# Configuration Modules

This directory contains configuration abstraction modules that define cross-cutting concerns and configuration patterns that can be used across different system components.

## Available Configuration Aspects

### `keybinds`
Desktop-agnostic keybind abstraction system that separates keybind definitions from desktop environment implementations.

**Features:**
- Abstract keybind definitions independent of desktop environment
- Consistent application mappings across different window managers
- Vim-style navigation keys for window management
- Semantic application bindings (AI, Notes, Browser, etc.)
- Automatic package installation for bound applications
- Helper functions to generate environment-specific bindings

**Usage:**
```nix
den.aspects.desktop-keybinds.enable = true;

# Customize keybinds in your home configuration
desktop.keybinds = {
  mod = "SUPER";  # Primary modifier
  apps = {
    terminal.key = "RETURN";
    browser.key = "B";
    files.key = "E";
    notes.key = "N";
    ai.key = "A";
    editor.key = "V";
    music.key = "M";
    password-manager.key = "K";
    launcher.key = "SPACE";
  };
  
  # Override default applications
  apps.browser.package = pkgs.firefox;
  apps.terminal.package = pkgs.alacritty;
};
```

**Default Keybind Layout:**
| Key | Application | Default Package |
|-----|-------------|-----------------|
| `Super + Return` | Terminal | kitty |
| `Super + B` | Browser | librewolf |
| `Super + E` | File Manager | nautilus |
| `Super + N` | Notes | obsidian |
| `Super + A` | AI Interface | ChatGPT (web) |
| `Super + V` | Editor | neovim |
| `Super + M` | Music | spotify |
| `Super + K` | Password Manager | bitwarden |
| `Super + Space` | Launcher | rofi-wayland |
| `Super + L` | Lock Screen | hyprlock |
| `Super + X` | Power Menu | power-menu |

**Window Management:**
| Key | Action |
|-----|--------|
| `Super + Q` | Close Window |
| `Super + T` | Toggle Floating |
| `Super + F` | Toggle Fullscreen |
| `Super + H/J/K/L` | Focus Left/Down/Up/Right |

## Design Philosophy

The config directory follows these principles:

### Separation of Concerns
Configuration aspects define "what you want" rather than "how to implement it". This allows the same configuration to work across different desktop environments and systems.

### Desktop Environment Agnostic
Configuration patterns should work whether you're using Hyprland, GNOME, KDE, or even macOS window managers. The implementation details are handled by environment-specific modules.

### Semantic Over Literal
Keybinds are defined by purpose (`ai`, `notes`, `browser`) rather than specific applications. This makes it easy to swap applications without changing muscle memory.

### Composable and Extensible
Each configuration aspect can be enabled independently and customized without affecting others.

## Implementation Pattern

Configuration aspects in this directory should follow this pattern:

```nix
{ lib, ... }:
{
  den.aspects.your-config-aspect = {
    description = "Brief description of what this configures";
    
    homeManager = { config, pkgs, lib, ... }: {
      # Define options that users can configure
      options.your.config.section = with lib.types; {
        # Configuration options here
      };
      
      # Provide sensible defaults and implementations
      config = {
        # Implementation that uses the options
      };
    };
  };
}
```

## Adding New Configuration Aspects

When adding new configuration aspects:

1. **Focus on abstraction** - Define what behavior you want, not how to implement it
2. **Provide good defaults** - Users should get a working setup without configuration
3. **Make it customizable** - Allow users to override defaults easily  
4. **Document thoroughly** - Include usage examples and option descriptions
5. **Test cross-platform** - Ensure it works on both NixOS and Darwin when applicable

## Integration with Desktop Environments

Configuration aspects define the abstract interface, while desktop environment modules (in `../desktop/environments/`) implement the concrete behavior. For example:

- `config/keybinds.nix` - Defines what keys should do what
- `desktop/environments/hyprland/keybinds.nix` - Implements those keybinds for Hyprland
- `desktop/environments/gnome/keybinds.nix` - Implements those keybinds for GNOME (future)

This separation allows you to switch desktop environments while keeping your familiar keybinds and applications.