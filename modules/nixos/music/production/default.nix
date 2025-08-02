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
    # Enable reaper by default when music production is enabled
    ${namespace}.music.production.reaper = enabled;
    
    # Enable plugins based on configuration
    ${namespace}.music.production.plugins.lsp = mkIf cfg.plugins.enable { enable = cfg.plugins.lsp; };
    ${namespace}.music.production.plugins.fabfilter = mkIf cfg.plugins.enable { enable = cfg.plugins.fabfilter; };
    ${namespace}.music.production.plugins.yabridge = mkIf cfg.plugins.enable { enable = cfg.plugins.yabridge; };
  };
} 