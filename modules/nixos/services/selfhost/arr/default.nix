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
  cfg = config.${namespace}.services.selfhost.arr;
in
{
  options.${namespace}.services.selfhost.arr = with types; {
    enable = mkBoolOpt false "Enable arr services (media management suite)";
  };

  config = mkIf cfg.enable {
    ${namespace}.services.selfhost.arr = {
      sonarr.enable = mkDefault true;
      radarr.enable = mkDefault true;
      bazarr.enable = mkDefault true;
      prowlarr.enable = mkDefault true;
      jellyseerr.enable = mkDefault true;
      lidarr.enable = mkDefault true;
    };
  };
} 