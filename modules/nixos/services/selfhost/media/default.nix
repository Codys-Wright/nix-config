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
  cfg = config.${namespace}.services.selfhost.media;
in
{
  options.${namespace}.services.selfhost.media = with types; {
    enable = mkBoolOpt false "Enable media services";
  };

  config = mkIf cfg.enable {
    ${namespace}.services.selfhost.media = {
      jellyfin.enable = mkDefault true;
      navidrome.enable = mkDefault false;
      audiobookshelf.enable = mkDefault true;
    };
  };
} 
