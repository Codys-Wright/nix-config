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
  cfg = config.${namespace}.programs.reaper;
in
{
  options.${namespace}.programs.reaper = {
    enable = mkBoolOpt false "Enable Reaper DAW";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Reaper DAW
      reaper
      
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

    # Configure audio settings
    home.sessionVariables = {
      # Set default audio backend
      AUDIO_BACKEND = "pulseaudio";
      
      # JACK settings
      JACK_NO_AUDIO_RESERVATION = "1";
      JACK_PROMISCUOUS_SERVER = "jackd";
    };
  };
} 