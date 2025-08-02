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
  cfg = config.${namespace}.music.production.plugins.lsp;
in
{
  options.${namespace}.music.production.plugins.lsp = with types; {
    enable = mkBoolOpt false ''
      Whether to enable LSP (Linux Studio Plugins) in the music production environment.
      
      This will add LSP plugins to system packages for use in DAWs.
      
      Example:
      ```nix
      FTS-FLEET = {
        music.production.plugins.lsp = enabled;
      };
      ```
    '';
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      lsp-plugins
    ];
  };
} 