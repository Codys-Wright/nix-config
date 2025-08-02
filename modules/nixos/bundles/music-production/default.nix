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
  cfg = config.${namespace}.bundles.music-production;
in
{
  options.${namespace}.bundles.music-production = with types; {
    enable = mkBoolOpt false "Whether or not to enable music production configuration.";
    
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
    # Enable musnix for real-time audio
    ${namespace}.music.musnix = enabled;
    
    # Enable music production environment
    ${namespace}.music.production = enabled;
    
    # Enable plugins based on configuration
    ${namespace}.music.production.plugins.lsp = mkIf cfg.plugins.enable { enable = cfg.plugins.lsp; };
    ${namespace}.music.production.plugins.fabfilter = mkIf cfg.plugins.enable { enable = cfg.plugins.fabfilter; };
    ${namespace}.music.production.plugins.yabridge = mkIf cfg.plugins.enable { enable = cfg.plugins.yabridge; };
  };
}
