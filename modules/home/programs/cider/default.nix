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
  cfg = config.${namespace}.programs.cider;
in
{
  options.${namespace}.programs.cider = {
    enable = mkBoolOpt false "Enable Cider-2 Apple Music client";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Cider-2 Apple Music client
      cider-2
      
      # Additional music players and tools
      spotify
      rhythmbox
      clementine
      
      # Audio format support
      mpv
      vlc
      
      # Music metadata tools
      picard
      easytag
      
      # Audio conversion tools
      ffmpeg
      sox
      
      # Music streaming tools
      yt-dlp
      youtube-dl
    ];

    # Configure Cider settings
    home.sessionVariables = {
      # Set Cider as default music player
      DEFAULT_MUSIC_PLAYER = "cider-2";
    };

    # Configure Cider settings directory
    home.file.".config/Cider" = {
      source = ./config;
      recursive = true;
      onChange = ''
        echo "Cider configuration updated"
      '';
    };
  };
} 