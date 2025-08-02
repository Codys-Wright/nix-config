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
  cfg = config.${namespace}.music.musnix;
in
{
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
  };
} 