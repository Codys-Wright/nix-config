{
  options,
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.music.production.musnix;
in
{
  imports = [ inputs.musnix.nixosModules.musnix ];

  options.${namespace}.music.production.musnix = with types; {
    enable = mkBoolOpt false "Enable musnix for real-time audio processing";
    kernel.realtime = mkBoolOpt false "Enable real-time kernel for musnix";
  };

  config = mkIf cfg.enable {
    # Musnix configuration for real-time audio
    musnix.enable = true;
    musnix.kernel.realtime = cfg.kernel.realtime;

    # Plugin path environment variables
    environment.variables = let
      makePluginPath = format:
        (lib.strings.makeSearchPath format [
          "$HOME/.nix-profile/lib"
          "/run/current-system/sw/lib"
          "/etc/profiles/per-user/$USER/lib"
        ])
        + ":$HOME/.${format}";
    in {
      DSSI_PATH   = lib.mkForce (makePluginPath "dssi");
      LADSPA_PATH = lib.mkForce (makePluginPath "ladspa");
      LV2_PATH    = lib.mkForce (makePluginPath "lv2");
      LXVST_PATH  = lib.mkForce (makePluginPath "lxvst");
      VST_PATH    = lib.mkForce (makePluginPath "vst");
      VST3_PATH   = lib.mkForce (makePluginPath "vst3");
    };

    # System activation script for plugin symlinks
    system.activationScripts.symlinkMusnixPlugins = {
      text = ''
        # Create /usr/lib directory if it doesn't exist
        mkdir -p /usr/lib
        
        plugin_types=("dssi" "ladspa" "lv2" "lxvst" "vst" "vst3")
        for plugintype in "''${plugin_types[@]}"; do
          # Check if the source directory exists in system profile
          if [[ -d "/run/current-system/sw/lib/$plugintype" ]]; then
            if [[ ! -h "/usr/lib/$plugintype" ]]; then
              ${pkgs.coreutils}/bin/ln -s "/run/current-system/sw/lib/$plugintype" "/usr/lib/$plugintype"
            fi
          else
            echo "Warning: /run/current-system/sw/lib/$plugintype does not exist, skipping symlink"
          fi
        done
      '';
      deps = [ "users" ];
    };

    # System activation script to create plugin symlinks in user home directories
    system.activationScripts.symlinkUserPluginDirectories = {
      text = ''
        # Create plugin symlinks in user home directories for all users
        for user_home in /home/*; do
          if [ -d "$user_home" ]; then
            username=$(basename "$user_home")
            
            plugin_types=("dssi" "ladspa" "lv2" "lxvst" "vst" "vst3")
            for plugintype in "''${plugin_types[@]}"; do
              # Create user plugin directory if it doesn't exist
              user_plugin_dir="$user_home/.$plugintype"
              mkdir -p "$user_plugin_dir"
              chown "$username" "$user_plugin_dir"
              
              # Check if the source directory exists in system profile
              if [[ -d "/run/current-system/sw/lib/$plugintype" ]]; then
                # Create symlinks for each plugin in the system directory
                for plugin in /run/current-system/sw/lib/$plugintype/*; do
                  if [[ -d "$plugin" ]]; then
                    plugin_name=$(basename "$plugin")
                    user_plugin_link="$user_plugin_dir/$plugin_name"
                    
                    # Only create symlink if it doesn't exist or is broken
                    if [[ ! -e "$user_plugin_link" ]] || [[ ! -L "$user_plugin_link" ]] || [[ ! -e "$user_plugin_link" ]]; then
                      ln -sf "$plugin" "$user_plugin_link"
                      chown -h "$username" "$user_plugin_link"
                    fi
                  fi
                done
              else
                echo "Warning: /run/current-system/sw/lib/$plugintype does not exist, skipping user symlinks for $username"
              fi
            done
          fi
        done
      '';
      deps = [ "users" ];
    };
  };
} 