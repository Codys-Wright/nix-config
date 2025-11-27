# System Modules

This directory contains system-level den aspects that can be used across both NixOS and macOS (Darwin) systems.

## Available Aspects

### `fonts`
Font configuration aspect that provides a comprehensive font setup.

**Features:**
- Programming fonts (JetBrains Mono, Fira Code)
- System fonts (Noto Sans, Roboto)
- CJK and emoji support
- Optional Apple Color Emoji support
- Microsoft fonts for compatibility

**Usage:**
```nix
den.aspects.fonts = {
  enable = true;
  enableAppleEmoji = true;  # Optional: Use Apple Color Emoji
  extraFonts = with pkgs; [
    # Add any additional fonts here
    comic-code
  ];
};
```

### `phoenix`
Cross-platform system management tool for Nix configurations.

**Features:**
- Works on both NixOS and macOS (Darwin)
- Sync system and user configurations
- Update flake inputs
- Garbage collection with age-based cleanup
- Platform-specific post-sync hooks
- Automatic hostname and username detection

**Usage:**
```nix
den.aspects.phoenix = {
  enable = true;
  dotfilesDir = "/path/to/your/nix-config";  # Optional: defaults to ~/nix-config
  defaultGcAge = "14d";  # Optional: default is 30d
  postHookScript = ''
    # Custom post-sync hooks
    echo "Custom hook executed!"
  '';
  extraRuntimeInputs = with pkgs; [
    # Additional tools available in phoenix scripts
    curl
    jq
  ];
};
```

**Commands:**
```bash
# Sync both system and user configurations
phoenix sync

# Sync only system configuration
phoenix sync system

# Sync only user configuration
phoenix sync user

# Update flake inputs
phoenix update

# Update inputs and rebuild everything
phoenix upgrade

# Garbage collection (uses defaultGcAge)
phoenix gc

# Garbage collection with specific age
phoenix gc 7d

# Full garbage collection (remove all old generations)
phoenix gc full

# Run post-sync hooks manually
phoenix posthook
```

## Platform Compatibility

| Aspect | NixOS | Darwin (macOS) |
|--------|-------|----------------|
| fonts  | ✅     | ✅              |
| phoenix| ✅     | ✅              |

## Implementation Notes

### Phoenix Cross-Platform Support

The phoenix aspect automatically detects the platform and uses the appropriate tools:

**NixOS:**
- Uses `nh` for system and home-manager operations
- Supports Hyprland, Waybar, and other Linux desktop environment hooks

**Darwin (macOS):**
- Uses `darwin-rebuild` for system operations
- Uses `home-manager` directly for user operations
- Supports yabai, skhd, sketchybar, and other macOS window manager hooks

### Font Configuration

The fonts aspect provides sensible defaults but can be customized:
- Default monospace font is JetBrains Mono
- Includes both Noto Color Emoji and optional Apple Color Emoji
- Microsoft Core Fonts included for document compatibility
- Powerline fonts for terminal prompt support

## Adding New System Aspects

To add a new system aspect:

1. Create a new `.nix` file in this directory
2. Follow the den aspects pattern with `config.den.aspects.your-aspect-name`
3. Add platform detection if needed using `pkgs.stdenv.isDarwin`
4. Update the aspects.nix file to include your new aspect in the default host includes
5. Document your aspect in this README

Example template:
```nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.den.aspects.your-aspect;
  
  # Platform detection
  isDarwin = pkgs.stdenv.isDarwin;
  isNixOS = !isDarwin;
in
{
  options.den.aspects.your-aspect = {
    enable = mkEnableOption "your aspect description";
  };

  config = mkIf cfg.enable {
    # NixOS-specific configuration
    environment = lib.optionalAttrs isNixOS {
      systemPackages = [ /* packages */ ];
    };

    # Darwin-specific configuration
    system = lib.optionalAttrs isDarwin {
      packages = [ /* packages */ ];
    };
  };
}
```
