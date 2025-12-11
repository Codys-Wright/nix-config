# Theme System Usage Guide

## Context-Aware Theme System

The theme system **automatically detects** whether it's being used at system or user level!

The same syntax works everywhere:

```nix
(<FTS/theme> { default = "theme-name"; })
```

### System-Level Theme

Applied in host configuration, affects:
- Bootloader theme (GRUB)
- Login screen appearance
- Default user themes
- System-wide package installations

```nix
# hosts/THEBATTLESHIP/THEBATTLESHIP.nix
den.aspects.THEBATTLESHIP = {
  includes = [
    # System-wide theme (uses mkDefault - can be overridden)
    (<FTS/theme> { default = "whitesur"; })
    
    (FTS.desktop {
      environment.default = "gnome";
      bootloader = {
        default = "grub";
        grub = {
          uefi = true;
          theme = "minegrub";  # Can override theme preset
        };
      };
    })
  ];
};
```

### User-Level Theme

Applied in user aspect, affects **only homeManager configs**:
- User's GTK/Qt theme
- User's icon theme
- User's cursor theme
- User's font preferences

**System configs (like bootloader) remain unchanged when used at user level.**

```nix
# users/cody/cody.nix
{
  FTS,
  cody,
  __findFile,  # Required for angle bracket syntax
  ...
}:
{
  den.aspects.cody = {
    includes = [
      # Same syntax! Automatically detects it's a user context
      (<FTS/theme> { default = "cody"; })
      
      # ... other user configs
    ];
  };
}
```

## Usage Examples

### Example 1: System Theme with User Override

```nix
# System: WhiteSur theme
den.aspects.THEBATTLESHIP = {
  includes = [
    (<FTS/theme> { default = "whitesur"; })
  ];
};

# User "cody": Custom theme that overrides system appearance
den.aspects.cody = {
  includes = [
    # Same syntax! Context-aware
    (<FTS/theme> { default = "cody"; })
  ];
};

# User "alice": Uses system theme (no override)
den.aspects.alice = {
  includes = [
    # No theme specified - inherits system theme
  ];
};
```

### Example 2: Different User Themes for Different Users

```nix
# User "cody" gets the "cody" theme
den.aspects.cody = {
  includes = [
    (<FTS/theme> { default = "cody"; })
  ];
};

# User "alice" gets the "whitesur" theme
den.aspects.alice = {
  includes = [
    (<FTS/theme> { default = "whitesur"; })
  ];
};

# User "bob" gets the "minecraft" theme
den.aspects.bob = {
  includes = [
    (<FTS/theme> { default = "minecraft"; })
  ];
};
```

## How It Works

### Context Detection

The theme module automatically detects its context by checking if `user` is in scope:

- **System context** (`user == null`): Full theme applies (bootloader + appearance)
- **User context** (`user != null`): Only homeManager configs apply

### How Themes Apply

1. **At System Level**:
   - Theme presets use `lib.mkDefault` for all settings
   - Applies to both nixos and homeManager
   - Provides system-wide defaults
   - Includes bootloader theming

2. **At User Level**:
   - Theme presets include the same modules
   - HomeManager configs apply (override system defaults)
   - NixOS configs use `lib.mkDefault` (won't override explicit system theme)
   - Result: User appearance changes, bootloader stays system-themed

### What Gets Applied Where

| Component | System Level | User Level |
|-----------|--------------|------------|
| Bootloader Theme | ✅ | ❌ |
| Login Screen | ✅ | ❌ |
| GTK Theme | ✅ (default) | ✅ (override) |
| Qt Theme | ✅ (default) | ✅ (override) |
| Icons | ✅ (default) | ✅ (override) |
| Cursors | ✅ (default) | ✅ (override) |
| Fonts | ✅ (system) | ✅ (user) |

### Benefits of This Approach

1. **Single Interface**: Same syntax for system and user themes
2. **Context-Aware**: Automatically does the right thing based on where it's used
3. **No Confusion**: Don't need to remember separate `FTS.theme._.user` syntax
4. **Consistent**: System and user use identical theme definitions
5. **Smart Defaults**: `lib.mkDefault` ensures proper override behavior

## Available Presets

- `minecraft` - Minecraft-inspired theme
- `whitesur` - macOS Big Sur style theme
- `cody` - WhiteSur + MineGrub combo

## Creating New Theme Presets

To add a new theme preset, create a file in `/modules/theme/presets/`:

```nix
# modules/theme/presets/my-theme.nix
{
  lib,
  FTS,
  ...
}:
{
  FTS.theme._.presets._.my-theme = {
    description = "My custom theme";
    includes = [
      (FTS.desktop {
        bootloader.grub.theme = lib.mkDefault "my-grub-theme";
        environment.gnome.theme = lib.mkDefault "my-gnome-theme";
      })
      (FTS.theme._.appearance._.gtk._.themes._.my-gtk {})
      (FTS.theme._.appearance._.icons._.themes._.my-icons {})
      # ... other components
    ];
  };
}
```

Then add `"my-theme"` to `availableThemes` list in `theme.nix`.

The context-aware system will automatically handle applying it correctly at system or user level!

