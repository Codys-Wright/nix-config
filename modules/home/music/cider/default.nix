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
  cfg = config.${namespace}.music.cider;
in
{
  options.${namespace}.music.cider = {
    enable = mkBoolOpt false "Enable Cider Apple Music client";
    pkg = mkOpt (types.enum [ "cider" "cider-2" ]) "cider" "Choose between Cider (version 1) or Cider-2 (version 2)";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Cider Apple Music client (free version from nixpkgs)
      cider
      
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
    ];

    # Configure Cider settings
    home.sessionVariables = {
      # Set Cider as default music player
      DEFAULT_MUSIC_PLAYER = "cider";
    };
  };
} 