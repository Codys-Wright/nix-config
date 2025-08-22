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
  cfg = config.${namespace}.bundles.office;
in
{
  options.${namespace}.bundles.office = with types; {
    enable = mkBoolOpt false "Enable office bundle";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      calibre
      libreoffice
      obsidian
      evince

      # planify
      newsflash
    ];

    services.nextcloud-client = {
      enable = false;
      package = pkgs.nextcloud-client;
      startInBackground = true;
    };
  };
}
