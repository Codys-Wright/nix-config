# Desktop Keybind Abstraction System

This module provides a powerful abstraction layer for desktop environment keybinds and applications, allowing you to define your keybind preferences once and apply them to different desktop environments.

## Architecture

```
modules/desktop/
├── abstractions/
│   └── keybinds.nix          # Core keybind abstractions
├── environments/
│   └── hyprland/
│       └── keybinds.nix      # Hyprland implementation
├── examples/
│   └── custom-keybinds.nix   # Customization examples
├── default.nix               # Main orchestrator
└── README.md                 # This file
```

## Concept

The system separates **what you want to do** from **how to do it** in a specific desktop environment:

- **Abstractions** define your preferred applications and keybinds (e.g., "A for AI", "N for Notes")
- **Implementations** translate these to desktop-environment-specific configurations
- **Customizations** let you override defaults for specific use cases

## Usage

### Basic Setup

1. **Enable the desktop abstraction** in your home configuration:
```nix
den.aspects.desktop-keybinds.enable = true;
```

2. **Choose a desktop environment** (currently supports Hyprland):
```nix
den.aspects.hyprland-keybinds.enable = true;
```

### Default Keybinds

The system comes with sensible defaults:

| Key | Application | Default Package |
|-----|-------------|----------------|
| `Super + Return` | Terminal | kitty |
| `Super + B` | Browser | librewolf |
| `Super + E` | File Manager | nautilus |
| `Super + N` | Notes | obsidian |
| `Super + A` | AI Webapp | (browser to ChatGPT) |
| `Super + V` | Editor | neovim (in terminal) |
| `Super + M` | Music | spotify |
| `Super + K` | Password Manager | bitwarden |
| `Super + Space` | Launcher | rofi |
| `Super + L` | Lock Screen | hyprlock |
| `Super + X` | Power Menu | power-menu |

### Window Management

| Key | Action |
|-----|--------|
| `Super + Q` | Close Window |
| `Super + T` | Toggle Floating |
| `Super + F` | Toggle Fullscreen |
| `Super + H/J/K/L` | Focus Left/Down/Up/Right |

## Customization

### Changing Applications

Override default applications in your configuration:

```nix
desktop.keybinds.apps = {
  terminal = {
    key = "RETURN";  # Keep same key
    package = pkgs.alacritty;
    command = "${pkgs.alacritty}/bin/alacritty";
  };
  
  browser = {
    key = "B";
    package = pkgs.firefox;
    command = "${pkgs.firefox}/bin/firefox";
  };
  
  notes = {
    key = "N";
    package = pkgs.logseq;
    command = "${pkgs.logseq}/bin/logseq";
  };
};
```

### Adding Custom Applications

Add new applications not in the defaults:

```nix
desktop.keybinds.apps = {
  calculator = {
    key = "C";
    package = pkgs.gnome-calculator;
    command = "${pkgs.gnome-calculator}/bin/gnome-calculator";
  };
  
  docker-ui = {
    key = "D";
    package = pkgs.lazydocker;
    command = "${config.desktop.keybinds.apps.terminal.command} -e ${pkgs.lazydocker}/bin/lazydocker";
  };
};
```

### Changing Keybinds

Remap keys while keeping the same applications:

```nix
desktop.keybinds.apps = {
  # Use 'W' for browser instead of 'B'
  browser.key = "W";
  
  # Use 'O' for notes instead of 'N'
  notes.key = "O";
};
```

### Profile-Specific Configurations

Create aspects for different workflows:

```nix
den.aspects.developer-keybinds = {
  description = "Developer-focused shortcuts";
  
  homeManager = { config, pkgs, ... }: {
    desktop.keybinds.apps = {
      ide = {
        key = "I";
        package = pkgs.vscode;
        command = "${pkgs.vscode}/bin/code";
      };
      
      database = {
        key = "shift+D";
        package = pkgs.dbeaver-bin;
        command = "${pkgs.dbeaver-bin}/bin/dbeaver";
      };
    };
  };
};
```

## Adding New Desktop Environments

To add support for a new desktop environment (e.g., GNOME):

1. **Create implementation file**: `environments/gnome/keybinds.nix`

2. **Implement the aspect**:
```nix
den.aspects.gnome-keybinds = {
  description = "GNOME desktop environment with abstracted keybinds";
  
  homeManager = { config, ... }: 
  let
    cfg = config.desktop.keybinds;
  in {
    # Convert abstract keybinds to GNOME dconf settings
    dconf.settings = {
      "org/gnome/desktop/wm/keybindings" = {
        close = ["<Super>${cfg.window.close.key}"];
        toggle-maximized = ["<Super>${cfg.window.toggle-fullscreen.key}"];
      };
      
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        binding = "<Super>${cfg.apps.terminal.key}";
        command = cfg.apps.terminal.command;
        name = "Terminal";
      };
    };
  };
};
```

3. **Update the main orchestrator** in `default.nix`

## Benefits

1. **Consistency**: Same keybinds work across different desktop environments
2. **Portability**: Easy to switch between desktop environments
3. **Maintainability**: One place to define your application preferences
4. **Flexibility**: Easy to create profiles for different workflows
5. **Extensibility**: Simple to add new desktop environments

## Implementation Details

The system uses NixOS module options to:
- Define abstract keybind mappings
- Store application preferences
- Generate desktop-environment-specific configurations
- Validate configurations at build time

The `generateAppBindings` and `generateWindowBindings` functions automatically create the proper keybind format for each desktop environment, ensuring consistency while allowing environment-specific optimizations.