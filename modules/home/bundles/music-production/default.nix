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
  cfg = config.${namespace}.bundles.music-production;
in
{
  options.${namespace}.bundles.music-production = with types; {
    enable = mkBoolOpt false "Enable music production bundle";
    
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
    home.packages = with pkgs; [ audacity ];
    ${namespace} = {
      music.production.reaper = enabled;
      
      # Enable plugins if the bundle is enabled and plugins are enabled
      music.production.plugins = mkIf cfg.plugins.enable {
        lsp.enable = cfg.plugins.lsp;
        fabfilter.enable = cfg.plugins.fabfilter;
        yabridge.enable = cfg.plugins.yabridge;
      };
    };
    
    # Set up user-specific plugin directory symlinks
    home.activation.setupUserPluginDirs = {
      after = [ "writeBoundary" ];
      before = [ ];
      data = ''
        plugin_types=("dssi" "ladspa" "lv2" "lxvst" "vst" "vst3")
        for plugintype in "''${plugin_types[@]}"; do
          # Create user plugin directories if they don't exist
          mkdir -p "$HOME/.$plugintype"
          
          # Check if user profile has plugins and create symlinks
          if [[ -d "$HOME/.nix-profile/lib/$plugintype" ]]; then
            echo "Setting up $plugintype plugins from user profile..."
            # Create symlinks for each plugin in the user profile
            for plugin in "$HOME/.nix-profile/lib/$plugintype"/*; do
              if [[ -d "$plugin" ]]; then
                plugin_name=$(basename "$plugin")
                if [[ ! -e "$HOME/.$plugintype/$plugin_name" ]]; then
                  ln -sf "$plugin" "$HOME/.$plugintype/$plugin_name"
                fi
              fi
            done
          fi
        done
      '';
    };
  };
} 