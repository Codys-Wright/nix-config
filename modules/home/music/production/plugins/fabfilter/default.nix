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
      it for use with yabridge.
      
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
    
    # Installation options
    autoInstall = mkBoolOpt false ''
      Automatically install FabFilter Total Bundle when the module is enabled.
      
      This will run the installer automatically during home-manager activation.
    '';
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      wine
      winetricks
      yabridge
      yabridgectl
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
    
    # Auto-install FabFilter if enabled
    home.activation.installFabfilter = lib.dag.entryAfter ["writeBoundary"] (lib.mkIf cfg.autoInstall ''
      echo "Installing FabFilter Total Bundle with yabridge integration..."
      
      # Run the comprehensive installer
      fabfilter-total-bundle-install
      
      # Apply yabridge configuration
      fabfilter-yabridge-config
      
      echo "FabFilter Total Bundle installation complete with yabridge integration."
    '');
  };
} 