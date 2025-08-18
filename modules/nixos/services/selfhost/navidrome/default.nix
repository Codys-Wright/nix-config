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
  cfg = config.${namespace}.services.selfhost.navidrome;
in
{
  options.${namespace}.services.selfhost.navidrome = with types; {
    enable = mkBoolOpt false "Enable navidrome";
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      last-fm-key = {
        owner = "navidrome";
      };
      last-fm-secret = {
        owner = "navidrome";
      };
    };

    services.navidrome = {
      enable = true;
      settings = {
        Address = "0.0.0.0";
        Port = 4533;
        MusicFolder = "/mnt/data/navidrome/music";
        LastFM.ApiKey = "$(cat ${config.sops.secrets.last-fm-key.path})";
        LastFM.Secret = "$(cat ${config.sops.secrets.last-fm-secret.path})";
      };
    };
    services.mpd = {
      enable = true;
      user = "navidrome";
      group = "navidrome";
      musicDirectory = "/mnt/data/navidrome/music";
      dataDir = "/mnt/data/navidrome/data";
      network = {
        port = 6600;
        listenAddress = "0.0.0.0";
      };
    };
  };
}
