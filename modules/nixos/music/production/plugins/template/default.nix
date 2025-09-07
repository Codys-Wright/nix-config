{
  options,
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.music.production.plugins.template;
in
{
  options.${namespace}.music.production.plugins.template = with types; {
    enable = mkBoolOpt false "Enable Template Plugin (example module)";
    
    # Plugin-specific configuration
    pluginName = mkOpt str "TemplatePlugin" "Name of the plugin for grouping";
    pluginGroup = mkOpt str "template" "Plugin group name for inter-plugin communication";
    
    # Installation options
    installerUrl = mkOpt str "" "URL to download the plugin installer";
    installerSha256 = mkOpt str "" "SHA256 hash of the installer";
    installerName = mkOpt str "installer.exe" "Name of the installer file";
    
    # Plugin locations (where the plugin gets installed in Wine)
    vst2Location = mkOpt str "" "VST2 plugin location in Wine (relative to drive_c)";
    vst3Location = mkOpt str "" "VST3 plugin location in Wine (relative to drive_c)";
    clapLocation = mkOpt str "" "CLAP plugin location in Wine (relative to drive_c)";
    
    # Configuration options
    createPluginGroup = mkBoolOpt true "Create a plugin group for this plugin";
    autoSync = mkBoolOpt true "Automatically sync yabridge after installation";
    installCorefonts = mkBoolOpt true "Install corefonts for better GUI compatibility";
  };

  config = mkIf cfg.enable {
    # Create a custom package for the plugin installer
    environment.systemPackages = with pkgs; [
      (pkgs.stdenv.mkDerivation rec {
        pname = "template-plugin-installer";
        version = "1.0.0";
        
        src = if cfg.installerUrl != "" then
          pkgs.fetchurl {
            url = cfg.installerUrl;
            sha256 = cfg.installerSha256;
          }
        else
          pkgs.writeText "dummy" "dummy";
        
        nativeBuildInputs = with pkgs; [ wine yabridge yabridgectl ];
        buildInputs = with pkgs; [ wine yabridge yabridgectl ];
        
        dontUnpack = true;
        
        installPhase = ''
          runHook preInstall
          
          # Create installation directory
          mkdir -p $out/share/template-plugin
          mkdir -p $out/bin
          
          # Copy the installer if URL was provided
          if [ -n "${cfg.installerUrl}" ]; then
            cp $src $out/share/template-plugin/${cfg.installerName}
          fi
          
          # Create installation script
          cat > $out/bin/template-plugin-install <<EOF
          #!${pkgs.bash}/bin/bash
          set -e
          
          echo "=== Template Plugin Installation ==="
          echo "This will install the template plugin and configure yabridge"
          
          # Set up Wine environment
          export WINEPREFIX=\$HOME/.wine
          export WINEARCH=win64
          
          # Create Wine prefix if it doesn't exist
          if [ ! -d "\$WINEPREFIX" ]; then
            echo "Creating Wine prefix..."
            wineboot --init
          fi
          
          # Install corefonts if enabled
          if [ "${cfg.installCorefonts}" = "true" ]; then
            echo "Installing corefonts for better GUI compatibility..."
            winetricks -q corefonts || echo "Warning: Could not install corefonts"
          fi
          
          # Create yabridge directories if they don't exist
          mkdir -p ~/.vst/yabridge
          mkdir -p ~/.vst3/yabridge
          mkdir -p ~/.clap/yabridge
          
          # Add plugin directories to yabridgectl
          if [ -n "${cfg.vst2Location}" ]; then
            echo "Adding VST2 directory to yabridge..."
            yabridgectl add "\$WINEPREFIX/drive_c/${cfg.vst2Location}" 2>/dev/null || true
          fi
          
          if [ -n "${cfg.vst3Location}" ]; then
            echo "Adding VST3 directory to yabridge..."
            yabridgectl add "\$WINEPREFIX/drive_c/${cfg.vst3Location}" 2>/dev/null || true
          fi
          
          if [ -n "${cfg.clapLocation}" ]; then
            echo "Adding CLAP directory to yabridge..."
            yabridgectl add "\$WINEPREFIX/drive_c/${cfg.clapLocation}" 2>/dev/null || true
          fi
          
          # Run the installer if URL was provided
          if [ -n "${cfg.installerUrl}" ]; then
            echo "Installing Template Plugin..."
            wine "\$out/share/template-plugin/${cfg.installerName}"
          else
            echo "No installer URL provided - manual installation required"
          fi
          
          # Create plugin group configuration if enabled
          if [ "${cfg.createPluginGroup}" = "true" ]; then
            echo "Creating plugin group configuration..."
            
            # VST2 configuration
            if [ -n "${cfg.vst2Location}" ]; then
              mkdir -p ~/.vst/yabridge
              cat >> ~/.vst/yabridge/yabridge.toml <<'TOML'
              
              # Template Plugin group configuration
              ["${cfg.pluginName}*.so"]
              group = "${cfg.pluginGroup}"
              TOML
            fi
            
            # VST3 configuration
            if [ -n "${cfg.vst3Location}" ]; then
              mkdir -p ~/.vst3/yabridge
              cat >> ~/.vst3/yabridge/yabridge.toml <<'TOML'
              
              # Template Plugin group configuration
              ["${cfg.pluginName}*.vst3"]
              group = "${cfg.pluginGroup}"
              TOML
            fi
          fi
          
          # Sync yabridge plugins if enabled
          if [ "${cfg.autoSync}" = "true" ]; then
            echo "Syncing yabridge plugins..."
            yabridgectl sync
          fi
          
          echo ""
          echo "=== Installation Complete ==="
          echo "Template Plugin has been installed and configured with yabridge."
          echo ""
          echo "Your plugins are now available in:"
          if [ -n "${cfg.vst2Location}" ]; then echo "  - VST2: ~/.vst/yabridge"; fi
          if [ -n "${cfg.vst3Location}" ]; then echo "  - VST3: ~/.vst3/yabridge"; fi
          if [ -n "${cfg.clapLocation}" ]; then echo "  - CLAP: ~/.clap/yabridge"; fi
          echo ""
          echo "Make sure your DAW is configured to scan these directories."
          EOF
          
          chmod +x $out/bin/template-plugin-install
          
          # Create configuration script
          cat > $out/bin/template-plugin-config <<EOF
          #!${pkgs.bash}/bin/bash
          echo "=== Template Plugin Yabridge Configuration ==="
          
          # Create yabridge.toml for the plugin
          if [ -n "${cfg.vst2Location}" ]; then
            mkdir -p ~/.vst/yabridge
            cat > ~/.vst/yabridge/yabridge.toml <<'TOML'
          # Template Plugin VST2 configuration
          ["${cfg.pluginName}*.so"]
          group = "${cfg.pluginGroup}"
          TOML
          fi
          
          if [ -n "${cfg.vst3Location}" ]; then
            mkdir -p ~/.vst3/yabridge
            cat > ~/.vst3/yabridge/yabridge.toml <<'TOML'
          # Template Plugin VST3 configuration
          ["${cfg.pluginName}*.vst3"]
          group = "${cfg.pluginGroup}"
          TOML
          fi
          
          echo "Yabridge configuration created for Template Plugin."
          echo "Run 'yabridgectl sync' to apply the configuration."
          EOF
          
          chmod +x $out/bin/template-plugin-config
          
          runHook postInstall
        '';
        
        meta = with lib; {
          description = "Template Plugin with Yabridge Integration - Example module";
          homepage = "https://example.com";
          license = licenses.unfree;
          platforms = platforms.linux;
          maintainers = [ ];
        };
      })
    ];
  };
}
