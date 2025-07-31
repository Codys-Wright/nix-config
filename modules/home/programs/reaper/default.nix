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
      
      # MIDI tools
      qmidictl
      qmidinet
      
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

    # Configure audio settings
    home.sessionVariables = {
      # Set default audio backend
      AUDIO_BACKEND = "pulseaudio";
      
      # JACK settings
      JACK_NO_AUDIO_RESERVATION = "1";
      JACK_PROMISCUOUS_SERVER = "jackd";
    };

    # Configure Reaper settings directory
    home.file.".config/REAPER" = {
      source = ./config;
      recursive = true;
      onChange = ''
        echo "Reaper configuration updated"
      '';
    };
  };
} 