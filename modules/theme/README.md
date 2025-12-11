# Theme Facet

The theme facet provides coordinated theming across your entire NixOS desktop environment.

## Features

- **Unified Theming**: Apply a single theme preset that configures bootloader, display manager, desktop environment, and applications
- **Override System**: All theme settings use `lib.mkDefault`, allowing you to override any specific component
- **Type Safety**: Theme presets only configure components they know about
- **Modular**: Easy to add new theme presets

## Architecture

```
FTS.theme/
├── theme.nix          # Main router
└── presets/
    ├── presets.nix    # Container
    ├── minecraft.nix  # Minecraft theme preset
    └── ...            # Future: catppuccin, nord, dracula, etc.
```

## Usage

### Apply a Complete Theme

```nix
(<FTS/theme> { default = "minecraft"; })
```

This will theme:
- GRUB bootloader (if enabled)
- SDDM/GDM (if enabled)
- GNOME/KDE/etc (if enabled)
- GTK/Qt applications

### Override Specific Components

Because all theme settings use `lib.mkDefault`, you can override any component:

```nix
# Use Minecraft theme but with a different GRUB background
(<FTS/theme> { default = "minecraft"; })

# Then in your host config:
nixos = {
  boot.loader.grub.minegrub-theme.background = "background_options/nether.png";
};
```

### Use Theme Preset Directly

```nix
(<FTS/theme/presets/minecraft> { })
```

## Creating New Theme Presets

1. Create a new file in `presets/`:

```nix
# presets/catppuccin.nix
{ FTS, lib, ... }:
{
  FTS.theme._.presets._.catppuccin = {
    description = "Catppuccin theme preset";
    
    nixos = {
      # Configure bootloader
      boot.loader.grub.theme = lib.mkDefault "catppuccin";
      
      # Configure display manager
      services.displayManager.sddm.theme = lib.mkDefault "catppuccin";
    };
    
    homeManager = {
      # Configure GTK
      gtk.theme.name = lib.mkDefault "Catppuccin-Mocha";
      
      # Configure Qt
      qt.style.name = lib.mkDefault "Catppuccin-Mocha";
    };
  };
}
```

2. Add the theme name to available themes in `theme.nix`:

```nix
availableThemes = ["minecraft" "catppuccin"];
```

## Design Principles

1. **All settings use `lib.mkDefault`**: This ensures user overrides always take precedence
2. **Conditional application**: Theme components only apply if the underlying system is enabled
3. **Scoped theming**: Themes configure specific components, not create global theme variables
4. **No hard dependencies**: Themes can reference other aspects but don't force them to be enabled

## Future Enhancements

- [ ] Add more theme presets (catppuccin, nord, dracula, gruvbox)
- [ ] Add Stylix integration for color scheme generation
- [ ] Add per-component theme override syntax
- [ ] Add theme variants (light/dark modes)
- [ ] Add custom color palette support

