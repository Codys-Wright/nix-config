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
  cfg = config.${namespace}.music.production.plugins;
in
{
  imports = [
    ./lsp
    ./fabfilter
    ./yabridge
  ];

  options.${namespace}.music.production.plugins = with types; {
    enable = mkBoolOpt false ''
      Whether to enable music production plugins.
      
      This will enable all configured plugins for use in DAWs.
      
      Example:
      ```nix
      FTS-FLEET = {
        music.production.plugins = enabled;
      };
      ```
    '';
    
    # Individual plugin options
    lsp = mkOpt (submodule {}) {} "LSP (Linux Studio Plugins) configuration";
    fabfilter = mkOpt (submodule {}) {} "FabFilter Total Bundle configuration";
    yabridge = mkOpt (submodule {}) {} "Yabridge Windows plugin bridging configuration";
  };

  config = mkIf cfg.enable {
    # Enable all plugins by default when the main plugins module is enabled
    ${namespace}.music.production.plugins = {
      lsp.enable = mkDefault true;
      fabfilter.enable = mkDefault true;
      yabridge.enable = mkDefault true;
    };
  };
} 