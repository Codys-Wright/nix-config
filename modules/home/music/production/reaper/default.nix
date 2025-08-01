{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.music.production.reaper;
in
{
  options.${namespace}.music.production.reaper = {
    enable = mkBoolOpt false "Enable Reaper DAW";
    
    # Yabridge integration
    enableYabridge = mkBoolOpt true ''
      Enable yabridge integration for Windows plugins.
      
      This will set up yabridge plugin directories and configure REAPER
      to use Windows plugins through yabridge.
    '';
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Reaper DAW
      reaper
      
      # Yabridge for Windows plugins
      yabridge
      yabridgectl
      
      # Audio tools and utilities
      audacity
      ardour
      
      # Audio plugins and effects
      calf
      lv2
      
      # Audio analysis tools
      sox
      ffmpeg
      
      # JACK audio system
      jack2
      qjackctl
      
      # ALSA utilities
      alsa-utils
      alsa-plugins
      
      # PulseAudio utilities
      pulseaudio
      pavucontrol
      
      # Audio file format support
      flac
      vorbis-tools
      mp3gain
      
      # Music notation
      musescore
      lilypond
      
      # Audio development libraries
      portaudio
      libsndfile
      fftw
    ];

    # Install REAPER extensions properly
    home.activation.installReaperExtensions = {
      after = [ "writeBoundary" ];
      before = [ ];
      data = ''
        mkdir -p "$HOME/.config/REAPER/UserPlugins"
        
        # Install SWS Extension
        if [ -f "${pkgs.reaper-sws-extension}/UserPlugins/reaper_sws-x86_64.so" ]; then
          ln -sf "${pkgs.reaper-sws-extension}/UserPlugins/reaper_sws-x86_64.so" "$HOME/.config/REAPER/UserPlugins/"
        fi
        
        # Install ReaPack Extension
        if [ -f "${pkgs.reaper-reapack-extension}/UserPlugins/reaper_reapack-x86_64.so" ]; then
          ln -sf "${pkgs.reaper-reapack-extension}/UserPlugins/reaper_reapack-x86_64.so" "$HOME/.config/REAPER/UserPlugins/"
        fi
        
        # Install SWS Scripts
        if [ -d "${pkgs.reaper-sws-extension}/Scripts" ]; then
          mkdir -p "$HOME/.config/REAPER/Scripts"
          cp -r "${pkgs.reaper-sws-extension}/Scripts/"* "$HOME/.config/REAPER/Scripts/" 2>/dev/null || true
        fi
      '';
    };

    # Set up yabridge for REAPER
    home.activation.setupYabridgeForReaper = lib.dag.entryAfter ["writeBoundary"] (lib.mkIf cfg.enableYabridge ''
      echo "Setting up yabridge for REAPER..."
      
      # Create yabridge plugin directories if they don't exist
      mkdir -p ~/.vst/yabridge
      mkdir -p ~/.vst3/yabridge
      mkdir -p ~/.clap/yabridge
      
      # Add common VST directories to yabridgectl
      yabridgectl add "$HOME/.wine/drive_c/Program Files/Steinberg/VstPlugins" 2>/dev/null || true
      yabridgectl add "$HOME/.wine/drive_c/Program Files/VstPlugins" 2>/dev/null || true
      yabridgectl add "$HOME/.wine/drive_c/Program Files/Common Files/VST3" 2>/dev/null || true
      yabridgectl add "$HOME/.wine/drive_c/Program Files/Common Files/CLAP" 2>/dev/null || true
      
      # Sync yabridge plugins
      yabridgectl sync 2>/dev/null || echo "Warning: Could not sync yabridge plugins"
      
      echo "Yabridge setup complete. Windows plugins will be available in REAPER."
      echo "Make sure REAPER is configured to scan ~/.vst, ~/.vst3, and ~/.clap directories."
    '');

    # Configure audio settings
    home.sessionVariables = {
      # Set default audio backend
      AUDIO_BACKEND = "pulseaudio";
      
      # JACK settings
      JACK_NO_AUDIO_RESERVATION = "1";
      JACK_PROMISCUOUS_SERVER = "jackd";
      
      # Yabridge settings
      WINEPREFIX = "$HOME/.wine";
      WINEARCH = "win64";
    };
  };
} 