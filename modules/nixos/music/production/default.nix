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
  cfg = config.${namespace}.music.production;
in
{
  options.${namespace}.music.production = with types; {
    enable = mkBoolOpt false "Enable music production environment at system level";
    
    # Plugin configuration
    plugins = mkOpt (submodule {
      options = {
        enable = mkBoolOpt true "Enable plugins by default";
        lsp = mkBoolOpt true "Enable LSP (Linux Studio Plugins)";
        fabfilter = mkBoolOpt true "Enable FabFilter Total Bundle";
        yabridge = mkBoolOpt true "Enable Yabridge for Windows plugins";
      };
    }) {
      enable = true;
      lsp = true;
      fabfilter = true;
      yabridge = true;
    } "Plugin configuration for music production";
  };

  config = mkIf cfg.enable {
    imports = [
      ./reaper
      ./plugins/lsp
      ./plugins/fabfilter
      ./plugins/yabridge
    ];

    # Enable reaper by default when music production is enabled
    ${namespace}.music.production.reaper = enabled;
    
    # Enable plugins if the bundle is enabled and plugins are enabled
    ${namespace}.music.production.plugins = mkIf cfg.plugins.enable {
      lsp.enable = cfg.plugins.lsp;
      fabfilter.enable = cfg.plugins.fabfilter;
      yabridge.enable = cfg.plugins.yabridge;
    };

    # Musnix configuration for real-time audio
    musnix.enable = true;
    musnix.kernel.realtime = false;

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