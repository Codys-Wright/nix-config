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
  cfg = config.${namespace}.services.selfhost.audiobookshelf;
in
{
  options.${namespace}.services.selfhost.audiobookshelf = with types; {
    enable = mkBoolOpt false "Enable audiobookshelf";
  };

  config = mkIf cfg.enable {

    fileSystems."/var/lib/audiobookshelf" = {
      device = "/mnt/data/audiobookshelf";
      options = [ "bind" ];
    };

    services.audiobookshelf = {
      enable = true;
      host = "0.0.0.0";
      port = 8008;
    };
    environment.systemPackages = [ pkgs.audiobookshelf ];

  };
}
