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
  cfg = config.${namespace}.music.production.plugins.vital;
in
{
  options.${namespace}.music.production.plugins.vital = with types; {
    enable = mkBoolOpt false ''
      Whether to enable Vital synthesizer in the music production environment.
      
      This will add Vital (native Linux VST3) to system packages for use in DAWs.
      
      Example:
      ```nix
      FTS-FLEET = {
        music.production.plugins.vital = enabled;
      };
      ```
    '';
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      vital
    ];
  };
}
