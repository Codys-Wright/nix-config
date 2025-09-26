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
  cfg = config.${namespace}.desktop.caelestia;
in
{
  imports = [ inputs.caelestia-shell.homeManagerModules.default ];

  options.${namespace}.desktop.caelestia = with types; {
    enable = mkBoolOpt false "Enable Caelestia shell";
  };

  config = mkIf cfg.enable {

    # Caelestia configuration
    programs.caelestia = {
      enable = true;
      systemd = {
        enable = false; # if you prefer starting from your compositor
        target = "graphical-session.target";
        environment = [];
      };
      settings = {
        bar.status = {
          showBattery = false;
        };
        paths.wallpaperDir = "~/Images";
      };
      cli = {
        enable = true; # Also add caelestia-cli to path
        settings = {
          # theme.enableGtk = false;
        };
      };
    };

    
  };
}
