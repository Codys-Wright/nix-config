{
  config,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.bundles.music-production;
in
{
  imports = [
    ../../music/production/plugins
  ];

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
    ${namespace} = {
      music.production.reaper = enabled;
      
      # Enable plugins if the bundle is enabled and plugins are enabled
      music.production.plugins = mkIf cfg.plugins.enable {
        enable = true;
        lsp.enable = cfg.plugins.lsp;
        fabfilter.enable = cfg.plugins.fabfilter;
        yabridge.enable = cfg.plugins.yabridge;
      };
    };
  };
} 