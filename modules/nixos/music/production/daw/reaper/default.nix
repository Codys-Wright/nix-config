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
  cfg = config.${namespace}.music.production.daw.reaper;
in
{
  options.${namespace}.music.production.daw.reaper = with types; {
    enable = mkBoolOpt false "Enable Reaper DAW at system level";
    
    # Yabridge integration
    enableYabridge = mkBoolOpt true ''
      Enable yabridge integration for Windows plugins.
      
      This will set up yabridge plugin directories and configure REAPER
      to use Windows plugins through yabridge.
    '';
  };

  config = mkIf cfg.enable {
    # Add users to audio and realtime groups for music production
    users.groups.audio.members = [ "cody" ];
    users.groups.realtime.members = [ "cody" ];
    
    # System packages for music production
    environment.systemPackages = with pkgs; [
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

    # System activation script for REAPER extensions
    system.activationScripts.installReaperExtensions = {
      text = ''
        # Install REAPER extensions for all users
        for user_home in /home/*; do
          if [ -d "$user_home" ]; then
            username=$(basename "$user_home")
            reaper_config="$user_home/.config/REAPER/UserPlugins"
            
            if [ ! -d "$reaper_config" ]; then
              mkdir -p "$reaper_config"
              chown "$username" "$reaper_config"
            fi
            
            # Install SWS Extension
            if [ -f "${pkgs.reaper-sws-extension}/UserPlugins/reaper_sws-x86_64.so" ]; then
              ln -sf "${pkgs.reaper-sws-extension}/UserPlugins/reaper_sws-x86_64.so" "$reaper_config/"
              # Don't try to chown symlinks as they're read-only in NixOS
            fi
            
            # Install ReaPack Extension
            if [ -f "${pkgs.reaper-reapack-extension}/UserPlugins/reaper_reapack-x86_64.so" ]; then
              ln -sf "${pkgs.reaper-reapack-extension}/UserPlugins/reaper_reapack-x86_64.so" "$reaper_config/"
              # Don't try to chown symlinks as they're read-only in NixOS
            fi
            
            # Install SWS Scripts
            if [ -d "${pkgs.reaper-sws-extension}/Scripts" ]; then
              scripts_dir="$user_home/.config/REAPER/Scripts"
              mkdir -p "$scripts_dir"
              cp -r "${pkgs.reaper-sws-extension}/Scripts/"* "$scripts_dir/" 2>/dev/null || true
              chown -R "$username" "$scripts_dir"
            fi
          fi
        done
      '';
      deps = [ "users" ];
    };

    # Set up yabridge for all users
    system.activationScripts.setupYabridgeForAllUsers = lib.mkIf cfg.enableYabridge {
      text = ''
        # Set up yabridge for all users
        for user_home in /home/*; do
          if [ -d "$user_home" ]; then
            username=$(basename "$user_home")
            
            # Create yabridge plugin directories
            mkdir -p "$user_home/.vst/yabridge"
            mkdir -p "$user_home/.vst3/yabridge"
            mkdir -p "$user_home/.clap/yabridge"
            chown -R "$username" "$user_home/.vst"
            chown -R "$username" "$user_home/.vst3"
            chown -R "$username" "$user_home/.clap"
            
            # Set up Wine prefix for the user
            wine_prefix="$user_home/.wine"
            if [ ! -d "$wine_prefix" ]; then
              mkdir -p "$wine_prefix"
              chown "$username" "$wine_prefix"
            fi
            
            # Add common VST directories to yabridgectl (run as user)
            if [ -x "$(command -v yabridgectl)" ]; then
              sudo -u "$username" yabridgectl add "$wine_prefix/drive_c/Program Files/Steinberg/VstPlugins" 2>/dev/null || true
              sudo -u "$username" yabridgectl add "$wine_prefix/drive_c/Program Files/VstPlugins" 2>/dev/null || true
              sudo -u "$username" yabridgectl add "$wine_prefix/drive_c/Program Files/Common Files/VST3" 2>/dev/null || true
              sudo -u "$username" yabridgectl add "$wine_prefix/drive_c/Program Files/Common Files/CLAP" 2>/dev/null || true
              
              # Sync yabridge plugins
              sudo -u "$username" yabridgectl sync 2>/dev/null || echo "Warning: Could not sync yabridge plugins for $username"
            fi
          fi
        done
      '';
      deps = [ "users" ];
    };

    # Environment variables for all users
    environment.variables = {
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