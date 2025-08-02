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
    # The individual modules (musnix, reaper, plugins) will handle their own enable/disable logic
    # when this module is enabled, they will be automatically enabled by snowfall-lib
  };
} 