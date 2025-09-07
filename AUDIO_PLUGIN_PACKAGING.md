# Audio Plugin Packaging with mkWindowsApp

This guide explains how to use the `mkWindowsApp` function from the erosanix repository to package proprietary audio plugins for use with yabridgectl on Linux.

## Overview

`mkWindowsApp` creates layered Wine bottles that provide:
- **Reproducible installations** - Each plugin gets its own isolated Wine environment
- **Rollback capability** - Can be rolled back with NixOS system rollbacks
- **Multiple versions** - Can install multiple versions simultaneously
- **Automatic persistence** - Settings and presets are automatically persisted

## How mkWindowsApp Works

### Layered Filesystem
mkWindowsApp creates a 3-layer overlay filesystem:

1. **Windows Layer** (read-only): Base Wine installation, shared across apps
2. **App Layer** (read-only): Your specific plugin installation
3. **Runtime Layer** (read-write): Temporary layer for runtime changes, discarded after use

### Storage Location
Layers are stored in `$HOME/.cache/mkWindowsApp/` (not the Nix store), with each layer identified by a hash of its dependencies.

## Basic Package Structure

```nix
{ lib
, erosanix
, wine
, fetchurl
, makeDesktopItem
, copyDesktopItems
, yabridge
, yabridgectl
}:

erosanix.lib.mkWindowsAppNoCC rec {
  inherit wine;

  pname = "your-plugin-name";
  version = "1.0.0";

  # Plugin installer
  src = fetchurl {
    url = "https://example.com/plugin-installer.exe";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  dontUnpack = true;
  wineArch = "win64"; # or "win32" for 32-bit plugins
  persistRegistry = true; # Important for plugin settings

  # Map plugin data to persistent Linux locations
  fileMap = {
    "$HOME/.config/your-plugin" = "drive_c/users/$USER/AppData/Roaming/YourPlugin";
    "$HOME/.local/share/your-plugin" = "drive_c/ProgramData/YourPlugin";
  };

  # Disable desktop symlink to prevent clutter
  enabledWineSymlinks = {
    desktop = false;
  };

  # Build inputs for the launcher script
  buildInputs = [ yabridge yabridgectl ];

  # Installation script
  winAppInstall = ''
    echo "Installing Your Plugin..."
    $WINE ${src} /S /D="C:\\Program Files\\YourPlugin"
    wineserver -w
    mkdir -p "$WINEPREFIX/drive_c/Program Files/YourPlugin"
  '';

  # Pre-run script (runs before each launch)
  winAppPreRun = ''
    echo "Setting up Your Plugin environment..."
    mkdir -p ~/.vst/yabridge
    mkdir -p ~/.vst3/yabridge
    yabridgectl add "$WINEPREFIX/drive_c/Program Files/YourPlugin" 2>/dev/null || true
    yabridgectl sync
  '';

  # Run script
  winAppRun = ''
    echo "Your Plugin is installed and configured with yabridge."
    echo "Plugins available in ~/.vst/yabridge and ~/.vst3/yabridge"
  '';

  nativeBuildInputs = [ copyDesktopItems ];

  # Desktop entry
  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = pname;
      icon = pname;
      desktopName = "Your Plugin";
      categories = ["AudioVideo" "Audio"];
    })
  ];

  installPhase = ''
    runHook preInstall
    ln -s $out/bin/.launcher $out/bin/${pname}
    runHook postInstall
  '';

  meta = with lib; {
    description = "Your Plugin - Professional audio plugin with yabridge integration";
    homepage = "https://example.com";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
  };
}
```

## Key Parameters Explained

### Essential Parameters
- `wine`: Wine version to use (usually `pkgs.wineWowPackages.stable`)
- `wineArch`: Architecture - "win64" for modern plugins, "win32" for older ones
- `persistRegistry`: Set to `true` for plugin settings and licensing
- `fileMap`: Maps Linux directories to Windows paths for persistence

### Installation Scripts
- `winAppInstall`: Runs once during installation
- `winAppPreRun`: Runs before each launch (good for yabridge setup)
- `winAppRun`: Main execution (usually just informational for VST plugins)
- `winAppPostRun`: Runs after each launch (cleanup)

### File Mapping
The `fileMap` attribute is crucial for persistence:

```nix
fileMap = {
  # Plugin settings and presets
  "$HOME/.config/your-plugin" = "drive_c/users/$USER/AppData/Roaming/YourPlugin";
  # Plugin data and samples
  "$HOME/.local/share/your-plugin" = "drive_c/ProgramData/YourPlugin";
  # License files
  "$HOME/.config/your-plugin/licenses" = "drive_c/users/$USER/AppData/Roaming/YourPlugin/Licenses";
};
```

## Integration with Yabridgectl

### Automatic Setup
The `winAppPreRun` script should:
1. Create yabridge directories
2. Add plugin directories to yabridgectl
3. Sync plugins

```nix
winAppPreRun = ''
  mkdir -p ~/.vst/yabridge
  mkdir -p ~/.vst3/yabridge
  mkdir -p ~/.clap/yabridge
  
  yabridgectl add "$WINEPREFIX/drive_c/Program Files/YourPlugin" 2>/dev/null || true
  yabridgectl add "$WINEPREFIX/drive_c/Program Files/Common Files/VST3" 2>/dev/null || true
  
  yabridgectl sync
'';
```

### Yabridge Configuration
Create a `yabridge.toml` file for plugin-specific settings:

```toml
# Plugin groups for inter-plugin communication
["YourPlugin.so"]
group = "yourplugin"

# Disable host scaling for better GUI performance
["YourPlugin.so"]
editor_disable_host_scaling = true
```

## Adding to Your Flake

### 1. Add erosanix Input
```nix
inputs = {
  # ... other inputs
  erosanix = {
    url = "github:emmanuelrosa/erosanix";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

### 2. Add to Overlay
```nix
overlays = with inputs; [
  snowfall-frost.overlays.default
  (final: prev: {
    your-plugin = final.callPackage ./packages/your-plugin { 
      erosanix = inputs.erosanix.lib;
    };
  })
];
```

### 3. Add to System Packages
```nix
environment.systemPackages = with pkgs; [
  # ... other packages
  your-plugin
];
```

## Usage

### Installation
```bash
# Install the package
nixos-rebuild switch

# Run the plugin installer
your-plugin
```

### Verification
```bash
# Check yabridge status
yabridgectl status

# List managed directories
yabridgectl list

# Sync plugins
yabridgectl sync
```

### DAW Configuration
Configure your DAW to scan:
- `~/.vst/yabridge` (VST2 plugins)
- `~/.vst3/yabridge` (VST3 plugins)
- `~/.clap/yabridge` (CLAP plugins)

## Advantages over Traditional Wine

### Benefits
1. **Isolation**: Each plugin gets its own Wine environment
2. **Reproducibility**: Consistent installations across systems
3. **Rollback**: Can rollback with NixOS system rollbacks
4. **Multiple versions**: Install multiple versions simultaneously
5. **Automatic persistence**: Settings automatically saved to Linux filesystem

### Garbage Collection
Run the garbage collector periodically:
```bash
nix run github:emmanuelrosa/erosanix#mkwindows-tools
```

## Troubleshooting

### Common Issues
1. **Plugin not appearing**: Run `yabridgectl sync`
2. **GUI issues**: Try `winetricks corefonts`
3. **Performance issues**: Check `yabridgectl status`
4. **Installation fails**: Check Wine logs in `$HOME/.cache/mkWindowsApp/`

### Debug Mode
Set environment variables for debugging:
```bash
WA_RUN_APP=0 your-plugin  # Drop to shell instead of running
WA_CLEAN_APP=1 your-plugin  # Clean app layer
```

### Manual Wine Access
To access Wine tools like `winecfg`:
```bash
WA_RUN_APP=0 your-plugin
# Now you're in a shell with WINEPREFIX set
winecfg
```

## Example: FabFilter Total Bundle

See `packages/fabfilter-mkwindowsapp/default.nix` for a complete example of packaging the FabFilter Total Bundle with mkWindowsApp.

## Best Practices

1. **Use `mkWindowsAppNoCC`** for lighter derivations (no GCC)
2. **Set `persistRegistry = true`** for plugin settings
3. **Map important directories** with `fileMap`
4. **Disable desktop symlink** to prevent clutter
5. **Use `winAppPreRun`** for yabridge setup
6. **Test thoroughly** before deploying

## Resources

- [mkWindowsApp Documentation](https://github.com/emmanuelrosa/erosanix/tree/main/pkgs/mkwindowsapp)
- [Yabridge Documentation](https://github.com/robbert-vdh/yabridge)
- [Example Packages](https://github.com/emmanuelrosa/erosanix/tree/main/pkgs)
