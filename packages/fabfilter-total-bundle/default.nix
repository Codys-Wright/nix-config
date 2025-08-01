{
  lib,
  inputs,
  namespace,
  pkgs,
  stdenv,
  fetchurl,
  wine,
  yabridge,
  yabridgectl,
  ...
}:

stdenv.mkDerivation rec {
  pname = "fabfilter-total-bundle";
  version = "1.0.0";

  src = fetchurl {
    url = "https://cdn-b.fabfilter.com/downloads/fftotalbundlex64.exe";
    sha256 = "sha256-oDwSjWWRQP0gPL+RSStbbWVhTmZM3vRppJJMuSLKbqk=";
  };

  nativeBuildInputs = with pkgs; [
    wine
    yabridge
    yabridgectl
  ];

  buildInputs = with pkgs; [
    wine
    yabridge
    yabridgectl
  ];

  # Skip unpack phase since we're dealing with a single .exe file
  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    
    # Create installation directory
    mkdir -p $out/share/fabfilter-total-bundle
    mkdir -p $out/bin
    
    # Copy the installer
    cp $src $out/share/fabfilter-total-bundle/fftotalbundlex64.exe
    
    # Create a comprehensive installer script that sets up yabridge
    cat > $out/bin/fabfilter-total-bundle-install <<EOF
    #!${pkgs.bash}/bin/bash
    set -e
    
    echo "=== FabFilter Total Bundle Installation ==="
    echo "This will install FabFilter plugins and configure yabridge for seamless integration"
    
    # Set up Wine environment
    export WINEPREFIX=\$HOME/.wine
    export WINEARCH=win64
    
    # Create Wine prefix if it doesn't exist
    if [ ! -d "\$WINEPREFIX" ]; then
      echo "Creating Wine prefix..."
      wineboot --init
    fi
    
    # Install corefonts for better GUI compatibility
    echo "Installing corefonts for better GUI compatibility..."
    winetricks -q corefonts || echo "Warning: Could not install corefonts"
    
    # Create yabridge directories
    echo "Setting up yabridge directories..."
    mkdir -p ~/.vst/yabridge
    mkdir -p ~/.vst3/yabridge
    mkdir -p ~/.clap/yabridge
    
    # Add common VST directories to yabridgectl
    echo "Configuring yabridgectl..."
    yabridgectl add "\$WINEPREFIX/drive_c/Program Files/Steinberg/VstPlugins" 2>/dev/null || true
    yabridgectl add "\$WINEPREFIX/drive_c/Program Files/VstPlugins" 2>/dev/null || true
    yabridgectl add "\$WINEPREFIX/drive_c/Program Files/Common Files/VST3" 2>/dev/null || true
    yabridgectl add "\$WINEPREFIX/drive_c/Program Files/Common Files/CLAP" 2>/dev/null || true
    
    # Run the FabFilter installer
    echo "Installing FabFilter Total Bundle..."
    INSTALLER_PATH=$(find /nix/store -name "fftotalbundlex64.exe" -path "*/fabfilter-total-bundle/*" 2>/dev/null | head -1)
    if [ -n "$INSTALLER_PATH" ]; then
      wine "$INSTALLER_PATH"
    else
      echo "Error: Could not find FabFilter installer"
      exit 1
    fi
    
    # Sync yabridge plugins
    echo "Syncing yabridge plugins..."
    yabridgectl sync
    
    echo ""
    echo "=== Installation Complete ==="
    echo "FabFilter Total Bundle has been installed and configured with yabridge."
    echo ""
    echo "Your plugins are now available in:"
    echo "  - VST2: ~/.vst/yabridge"
    echo "  - VST3: ~/.vst3/yabridge"
    echo "  - CLAP: ~/.clap/yabridge"
    echo ""
    echo "Make sure your DAW is configured to scan these directories:"
    echo "  - REAPER: Options > Preferences > Plug-ins > VST"
    echo "  - Bitwig: Settings > Locations > VST Plug-ins"
    echo ""
    echo "To manage plugins, use:"
    echo "  - yabridgectl list    # List managed directories"
    echo "  - yabridgectl status  # Check plugin status"
    echo "  - yabridgectl sync    # Sync after installing new plugins"
    EOF
    
    chmod +x $out/bin/fabfilter-total-bundle-install
    
    # Create a configuration script for yabridge
    cat > $out/bin/fabfilter-yabridge-config <<EOF
    #!${pkgs.bash}/bin/bash
    echo "=== FabFilter Yabridge Configuration ==="
    
    # Create yabridge.toml for FabFilter plugins
    mkdir -p ~/.vst/yabridge
    mkdir -p ~/.vst3/yabridge
    
    # VST2 configuration
    cat > ~/.vst/yabridge/yabridge.toml <<'TOML'
    # FabFilter plugin groups for inter-plugin communication
    ["FabFilter Pro-Q 3.so"]
    group = "fabfilter"
    
    ["FabFilter Pro-C 2.so"]
    group = "fabfilter"
    
    ["FabFilter Pro-L 2.so"]
    group = "fabfilter"
    
    ["FabFilter Pro-R.so"]
    group = "fabfilter"
    
    ["FabFilter Saturn 2.so"]
    group = "fabfilter"
    
    ["FabFilter Timeless 3.so"]
    group = "fabfilter"
    
    ["FabFilter Volcano 3.so"]
    group = "fabfilter"
    
    ["FabFilter Twin 3.so"]
    group = "fabfilter"
    
    ["FabFilter One.so"]
    group = "fabfilter"
    
    ["FabFilter Simplon.so"]
    group = "fabfilter"
    
    ["FabFilter Micro.so"]
    group = "fabfilter"
    
    ["FabFilter Pro-DS.so"]
    group = "fabfilter"
    
    ["FabFilter Pro-G.so"]
    group = "fabfilter"
    
    ["FabFilter Pro-MB.so"]
    group = "fabfilter"
    
    ["FabFilter Pro-NR.so"]
    group = "fabfilter"
    
    ["FabFilter Pro-R.so"]
    group = "fabfilter"
    
    ["FabFilter Pro-Q 3.so"]
    editor_disable_host_scaling = true
    TOML
    
    # VST3 configuration
    cat > ~/.vst3/yabridge/yabridge.toml <<'TOML'
    # FabFilter VST3 plugins
    ["FabFilter*.vst3"]
    group = "fabfilter"
    editor_disable_host_scaling = true
    TOML
    
    echo "Yabridge configuration created for FabFilter plugins."
    echo "Run 'yabridgectl sync' to apply the configuration."
    EOF
    
    chmod +x $out/bin/fabfilter-yabridge-config
    
    # Create a README
    cat > $out/share/fabfilter-total-bundle/README.md <<EOF
    # FabFilter Total Bundle with Yabridge Integration
    
    This package provides the FabFilter Total Bundle installer with seamless
    yabridge integration for running Windows plugins in Linux DAWs.
    
    ## Installation
    
    Run the installer with:
    \`\`\`bash
    fabfilter-total-bundle-install
    \`\`\`
    
    This will:
    1. Set up Wine prefix
    2. Install corefonts for better GUI
    3. Configure yabridge directories
    4. Install FabFilter Total Bundle
    5. Sync plugins with yabridge
    
    ## Configuration
    
    After installation, configure yabridge for optimal FabFilter performance:
    \`\`\`bash
    fabfilter-yabridge-config
    \`\`\`
    
    ## Requirements
    
    - Wine Staging 9.21 (not 9.22 or 10.x)
    - Linux kernel 5.16+ for fsync support
    - Realtime privileges for optimal performance
    
    ## Performance Tuning
    
    For best performance, enable realtime privileges:
    \`\`\`bash
    # On Arch/Manjaro
    sudo gpasswd -a \$USER realtime
    
    # On Ubuntu/Debian
    sudo usermod -a -G audio \$USER
    \`\`\`
    
    Then reboot your system.
    
    ## Troubleshooting
    
    - If plugins don't appear in your DAW, run: \`yabridgectl sync\`
    - For GUI issues, try: \`winetricks corefonts\`
    - For performance issues, check: \`yabridgectl status\`
    
    ## Plugin Groups
    
    FabFilter plugins are configured to run in a single process group,
    enabling inter-plugin communication (e.g., Pro-Q 3 spectrum analyzer
    showing in other FabFilter plugins).
    
    ## Notes
    
    - Plugins are available in ~/.vst/yabridge, ~/.vst3/yabridge, ~/.clap/yabridge
    - Make sure your DAW scans these directories
    - Use VST3 versions when possible for better performance
    EOF
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "FabFilter Total Bundle with Yabridge Integration - Professional Audio Plugins for Linux";
    homepage = "https://www.fabfilter.com/products/total-bundle";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [ ];
  };
} 