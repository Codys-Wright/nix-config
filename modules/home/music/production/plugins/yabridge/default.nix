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
  cfg = config.${namespace}.music.production.plugins.yabridge;
in
{
  options.${namespace}.music.production.plugins.yabridge = with types; {
    enable = mkBoolOpt false ''
      Whether to enable yabridge for Windows plugin bridging.
      
      This will install yabridge and yabridgectl for running Windows VST2, VST3, 
      and CLAP plugins in Linux DAWs through Wine.
      
      Example:
      ```nix
      ${namespace} = {
        music.production.plugins.yabridge = enabled;
      };
      ```
    '';
    
    winePrefix = mkOpt str "$HOME/.wine" ''
      Wine prefix directory for Windows plugins.
      
      This is where Windows plugins will be installed and managed.
    '';
    
    # Plugin directories to manage
    vst2Directories = mkOpt (listOf str) [
      "$HOME/.wine/drive_c/Program Files/Steinberg/VstPlugins"
      "$HOME/.wine/drive_c/Program Files/VstPlugins"
    ] ''
      VST2 plugin directories to manage with yabridgectl.
      
      These directories will be added to yabridge's managed plugin list.
    '';
    
    vst3Directories = mkOpt (listOf str) [
      "$HOME/.wine/drive_c/Program Files/Common Files/VST3"
    ] ''
      VST3 plugin directories to manage with yabridgectl.
      
      These directories will be added to yabridge's managed plugin list.
    '';
    
    clapDirectories = mkOpt (listOf str) [
      "$HOME/.wine/drive_c/Program Files/Common Files/CLAP"
    ] ''
      CLAP plugin directories to manage with yabridgectl.
      
      These directories will be added to yabridge's managed plugin list.
    '';
    
    # Configuration options
    enableFsync = mkBoolOpt true ''
      Enable fsync for better performance with compatible Wine versions.
      
      Requires Wine compiled with fsync patches and Linux kernel 5.16+.
    '';
    
    enableRealtime = mkBoolOpt true ''
      Enable realtime scheduling for better performance.
      
      Requires realtime privileges to be set up for the user.
    '';
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      yabridge
      yabridgectl
      wine
      winetricks
    ];
    
    # Set up Wine environment variables
    home.sessionVariables = {
      WINEPREFIX = cfg.winePrefix;
      WINEARCH = "win64";
    } // lib.optionalAttrs cfg.enableFsync {
      WINEFSYNC = "1";
    };
    
    # Create Wine prefix and set up yabridge
    home.activation.setupYabridge = lib.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${cfg.winePrefix}
      $DRY_RUN_CMD echo "Setting up yabridge in ${cfg.winePrefix}..."
      
      # Add VST2 directories to yabridgectl
      ${lib.concatStringsSep "\n" (map (dir: ''
        $DRY_RUN_CMD yabridgectl add "${dir}" || echo "Warning: Could not add VST2 directory ${dir}"
      '') cfg.vst2Directories)}
      
      # Add VST3 directories to yabridgectl
      ${lib.concatStringsSep "\n" (map (dir: ''
        $DRY_RUN_CMD yabridgectl add "${dir}" || echo "Warning: Could not add VST3 directory ${dir}"
      '') cfg.vst3Directories)}
      
      # Add CLAP directories to yabridgectl
      ${lib.concatStringsSep "\n" (map (dir: ''
        $DRY_RUN_CMD yabridgectl add "${dir}" || echo "Warning: Could not add CLAP directory ${dir}"
      '') cfg.clapDirectories)}
      
      # Sync yabridge plugins
      $DRY_RUN_CMD yabridgectl sync || echo "Warning: Could not sync yabridge plugins"
    '';
    
    # Create yabridge configuration directories
    home.activation.createYabridgeDirs = lib.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/.vst/yabridge
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/.vst3/yabridge
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ~/.clap/yabridge
      $DRY_RUN_CMD echo "Created yabridge plugin directories"
    '';
    
    # Set up realtime privileges if enabled
    home.activation.setupRealtime = lib.dag.entryAfter ["writeBoundary"] (lib.mkIf cfg.enableRealtime ''
      $DRY_RUN_CMD echo "Note: For realtime privileges, ensure your user is in the 'realtime' group"
      $DRY_RUN_CMD echo "On Arch/Manjaro: sudo gpasswd -a $USER realtime"
      $DRY_RUN_CMD echo "On Ubuntu/Debian: sudo usermod -a -G audio $USER"
      $DRY_RUN_CMD echo "Then reboot your system"
    '');
  };
} 