# Theme System Examples

## How Theme Presets Work

Theme presets configure FTS aspects with theme parameters using `lib.mkDefault`. This means:
- The theme provides sensible defaults
- You can override any specific component
- Themes don't set NixOS options directly - they configure FTS aspects

## Example 1: Use Complete Theme

```nix
# hosts/myhost.nix
{
  den.aspects.myhost = {
    includes = [
      # Apply Minecraft theme across everything
      (<FTS/theme> { default = "minecraft"; })
      
      # Configure desktop (theme will apply to bootloader)
      (FTS.desktop {
        environment.default = "gnome";
        bootloader.default = "grub";
        displayManager.auto = true;
      })
    ];
  };
}
```

Result: GRUB will automatically get the `minegrub` theme from the Minecraft preset.

## Example 2: Theme with Override

```nix
{
  den.aspects.myhost = {
    includes = [
      # Apply Minecraft theme
      (<FTS/theme> { default = "minecraft"; })
      
      # Override just the bootloader theme
      (FTS.desktop {
        environment.default = "gnome";
        bootloader = {
          default = "grub";
          grub.theme = "minegrub-world-sel";  # Override theme!
        };
        displayManager.auto = true;
      })
    ];
  };
}
```

Result: Uses Minecraft theme for everything EXCEPT GRUB, which uses `minegrub-world-sel` instead.

## Example 3: Direct Preset Access

```nix
{
  den.aspects.myhost = {
    includes = [
      # Use preset directly
      (<FTS/theme/presets/minecraft> { })
      
      (FTS.desktop {
        environment.default = "gnome";
        bootloader.default = "grub";
      })
    ];
  };
}
```

## How to Create a New Theme Preset

```nix
# modules/theme/presets/catppuccin.nix
{ FTS, lib, ... }:
{
  FTS.theme._.presets._.catppuccin = {
    description = "Catppuccin theme preset";
    
    includes = [
      # Configure bootloader theme
      (FTS.desktop {
        bootloader.grub.theme = lib.mkDefault "catppuccin";
      })
      
      # Configure display manager theme (future)
      # (FTS.desktop {
      #   displayManager.sddm.theme = lib.mkDefault "catppuccin";
      # })
      
      # Configure GTK theme (future)
      # (FTS.gtk { theme = lib.mkDefault "Catppuccin-Mocha"; })
    ];
  };
}
```

Then add to available themes in `theme.nix`:
```nix
availableThemes = ["minecraft" "catppuccin"];
```

## Architecture

```
Theme Preset (minecraft)
  ↓ includes
FTS.desktop { bootloader.grub.theme = "minegrub"; }
  ↓ calls
FTS.grub { theme = "minegrub"; }
  ↓ includes
FTS.grub._.themes._.minegrub
  ↓ sets
boot.loader.grub.minegrub-theme.enable = true
```

This layered approach means:
1. Theme presets are just organized collections of aspect configurations
2. All type checking happens at the aspect level
3. Overrides work naturally through Nix's module system
4. Easy to see what a theme actually does

