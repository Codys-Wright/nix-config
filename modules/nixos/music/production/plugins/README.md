# Modular Windows Plugin System for NixOS

This system provides a fully declarative way to manage Windows audio plugins through yabridge in NixOS. Each plugin becomes a NixOS module that handles its own installation, Wine setup, and yabridge configuration.

## How It Works

### 1. **Base Infrastructure** (`yabridge` module)
- Sets up Wine prefixes and drive structure
- Creates yabridge plugin directories
- Manages audio and realtime groups
- Handles core yabridge configuration

### 2. **Individual Plugin Modules**
Each plugin module provides:
- **Installation scripts**: Automated Wine installation
- **Configuration scripts**: yabridge.toml setup
- **Plugin grouping**: Performance optimization
- **Documentation**: Usage and troubleshooting

## Usage

### Enable the System

```nix
FTS-FLEET = {
  music.production = enabled;
  
  music.production.plugins = {
    yabridge = enabled;
    serum = enabled;
    # Add more plugins as needed
  };
};
```

### Install Plugins

After enabling a plugin module, you get installation scripts:

```bash
# Install Serum
serum-install

# Configure yabridge for Serum
serum-config

# Check status
yabridgectl status
```

## Creating New Plugin Modules

### 1. Copy the Template

```bash
cp -r template your-plugin-name
```

### 2. Customize the Module

Edit `your-plugin-name/default.nix`:

```nix
options.${namespace}.music.production.plugins.yourPlugin = with types; {
  enable = mkBoolOpt false "Enable Your Plugin";
  
  # Plugin-specific options
  installerUrl = mkOpt str "https://example.com/installer.exe" "Download URL";
  installerSha256 = mkOpt str "sha256-hash-here" "SHA256 hash";
  
  # Plugin locations in Wine
  vst2Location = mkOpt str "Program Files/YourCompany/YourPlugin" "VST2 location";
  vst3Location = mkOpt str "Program Files/Common Files/VST3" "VST3 location";
};
```

### 3. Add to Main Plugins Module

```nix
# modules/nixos/music/production/plugins/default.nix
{
  imports = [
    ./yabridge
    ./your-plugin-name
  ];
}
```

## Plugin Module Structure

```
plugins/
├── yabridge/          # Core infrastructure
├── template/          # Template for new plugins
├── serum/            # Example: Serum synthesizer
├── fabfilter/        # Example: FabFilter bundle
└── lsp/              # Native Linux plugins
```

## Benefits

- **Fully Declarative**: All configuration in NixOS
- **Reproducible**: Same setup across all systems
- **Modular**: Add/remove plugins independently
- **Automated**: Wine setup and yabridge config handled automatically
- **Performance**: Plugin grouping and optimization built-in

## Example: Adding Serum

```nix
# In your system configuration
FTS-FLEET.music.production.plugins.serum = {
  enable = true;
  installerUrl = "https://xferrecords.com/downloads/Serum_x64.exe";
  installerSha256 = "actual-sha256-hash-here";
  enableWavetableSharing = true;
};
```

Then rebuild and run:
```bash
sudo nixos-rebuild switch
serum-install
```

## Troubleshooting

### Plugin Not Appearing in DAW
```bash
yabridgectl sync
yabridgectl status
```

### Wine Issues
```bash
winetricks corefonts
export WINEFSYNC=1
```

### Performance Issues
```bash
# Check realtime privileges
groups $USER
# Add to realtime group if needed
sudo gpasswd -a $USER realtime
```

## Advanced Configuration

### Custom Plugin Groups
```nix
FTS-FLEET.music.production.plugins.serum = {
  enable = true;
  pluginGroup = "synths";  # Custom group name
  createPluginGroup = true;
};
```

### Multiple Plugin Locations
```nix
FTS-FLEET.music.production.plugins.yourPlugin = {
  enable = true;
  vst2Location = "Program Files/Company/Plugin";
  vst3Location = "Program Files/Common Files/VST3";
  clapLocation = "Program Files/Common Files/CLAP";
};
```

## Environment Variables

The system automatically sets:
- `WINEPREFIX=$HOME/.wine`
- `WINEARCH=win64`
- `WINEFSYNC=1` (if enabled)

Add to `~/.zprofile` for GUI applications:
```bash
export WINEFSYNC=1
export WINEPREFIX=$HOME/.wine
export WINEARCH=win64
```

## Best Practices

1. **Always use Wine Staging 9.21** (avoid 9.22+ and 10.x)
2. **Enable realtime privileges** for optimal performance
3. **Use plugin groups** for related plugins
4. **Keep Wine prefixes clean** - let modules manage them
5. **Test plugins individually** before adding to production

## Contributing

To add a new plugin:
1. Copy the template module
2. Customize for your plugin
3. Test installation and configuration
4. Add to the main plugins module
5. Document any special requirements
