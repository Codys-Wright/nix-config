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
  cfg = config.${namespace}.music.production.plugins.fabfilter;
in
{
  options.${namespace}.music.production.plugins.fabfilter = with types; {
    enable = mkBoolOpt false ''
      Whether to enable FabFilter Total Bundle in the music production environment.
      
      This will add the FabFilter Total Bundle installer to system packages.
      
      Example:
      ```nix
      FTS-FLEET = {
        music.production.plugins.fabfilter = enabled;
      };
      ```
    '';
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      inputs.self.packages.${pkgs.system}.fabfilter-total-bundle
    ];
  };
}