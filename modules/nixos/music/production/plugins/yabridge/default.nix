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
      FTS-FLEET = {
        music.production.plugins.yabridge = enabled;
      };
      ```
    '';
    
    # Wine configuration
    winePrefix = mkOpt str "$HOME/.wine" "Wine prefix directory for Windows plugins";
    wineArch = mkOpt str "win64" "Wine architecture (win32 or win64)";
    enableFsync = mkBoolOpt true "Enable fsync for better performance";
    
    # Plugin management
    autoSync = mkBoolOpt true "Automatically sync yabridge after plugin installation";
    createPluginGroups = mkBoolOpt true "Create plugin groups for related plugins";
    
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
    enableRealtime = mkBoolOpt true "Enable realtime scheduling for better performance";
  };

  config = mkIf cfg.enable {
    # Add users to audio and realtime groups for music production
    users.groups.audio.members = [ "cody" ];
    users.groups.realtime.members = [ "cody" ];
    
    # Core packages for Windows plugin support
    environment.systemPackages = with pkgs; [
      yabridge
      yabridgectl
      wineWowPackages.stable  # Support both 32-bit and 64-bit applications
      wineWowPackages.yabridge # Yabridge-optimized Wine for audio plugins
      winePackages.fonts      # Microsoft fonts for better GUI compatibility
      winetricks
    ];
    
    # Set up Wine environment variables for all users
    environment.variables = {
      WINEPREFIX = cfg.winePrefix;
      WINEARCH = cfg.wineArch;
    } // lib.optionalAttrs cfg.enableFsync {
      WINEFSYNC = "1";
    };
    
    # System activation script to set up yabridge infrastructure for all users
    system.activationScripts.setupYabridgeInfrastructure = {
      text = ''
        # Set up yabridge infrastructure for all users
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
            
            # Create Wine drive structure
            mkdir -p "$wine_prefix/drive_c/Program Files"
            mkdir -p "$wine_prefix/drive_c/Program Files/Common Files"
            mkdir -p "$wine_prefix/drive_c/Program Files/Steinberg"
            chown -R "$username" "$wine_prefix/drive_c"
            
            # Add configured VST2 directories to yabridgectl (run as user)
            if [ -x "$(command -v yabridgectl)" ]; then
              ${lib.concatStringsSep "\n" (map (dir: ''
                sudo -u "$username" yabridgectl add "${dir}" 2>/dev/null || echo "Warning: Could not add VST2 directory ${dir} for $username"
              '') cfg.vst2Directories)}
              
              # Add configured VST3 directories to yabridgectl (run as user)
              ${lib.concatStringsSep "\n" (map (dir: ''
                sudo -u "$username" yabridgectl add "${dir}" 2>/dev/null || echo "Warning: Could not add VST3 directory ${dir} for $username"
              '') cfg.vst3Directories)}
              
              # Add configured CLAP directories to yabridgectl (run as user)
              ${lib.concatStringsSep "\n" (map (dir: ''
                sudo -u "$username" yabridgectl add "${dir}" 2>/dev/null || echo "Warning: Could not add CLAP directory ${dir} for $username"
              '') cfg.clapDirectories)}
              
              # Sync yabridge plugins
              sudo -u "$username" yabridgectl sync 2>/dev/null || echo "Warning: Could not sync yabridge plugins for $username"
            fi
          fi
        done
      '';
      deps = [ "users" ];
    };
    
    # Set up realtime privileges if enabled
    system.activationScripts.setupRealtimePrivileges = lib.mkIf cfg.enableRealtime {
      text = ''
        echo "Note: For realtime privileges, ensure users are in the 'realtime' group"
        echo "On Arch/Manjaro: sudo gpasswd -a USERNAME realtime"
        echo "On Ubuntu/Debian: sudo usermod -a -G audio USERNAME"
        echo "Then reboot your system"
      '';
      deps = [ "users" ];
    };
  };
} 