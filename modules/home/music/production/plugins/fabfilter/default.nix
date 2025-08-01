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
  cfg = config.${namespace}.music.production.plugins.fabfilter;
in
{
  options.${namespace}.music.production.plugins.fabfilter = with types; {
    enable = mkBoolOpt false ''
      Whether to enable FabFilter Total Bundle in the music production environment.
      
      This will add the FabFilter Total Bundle installer to home.packages and configure
      Wine for plugin installation.
      
      Example:
      ```nix
      FTS-FLEET = {
        music.production.plugins.fabfilter = enabled;
      };
      ```
    '';
    
    winePrefix = mkOpt str "$HOME/.wine" ''
      Wine prefix directory for FabFilter plugins.
      
      This is where the plugins will be installed.
    '';
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wine
      fabfilter-total-bundle
    ];
    
    # Set up Wine environment variables
    home.sessionVariables = {
      WINEPREFIX = cfg.winePrefix;
      WINEARCH = "win64";
    };
    
    # Create Wine prefix directory
    home.activation.setupFabfilterWine = lib.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p $VERBOSE_ARG ${cfg.winePrefix}
      $DRY_RUN_CMD echo "FabFilter Wine prefix directory created at ${cfg.winePrefix}"
    '';
  };
} 