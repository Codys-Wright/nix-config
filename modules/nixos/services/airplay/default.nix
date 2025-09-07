{
  options,
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.airplay;
in
{
  options.${namespace}.services.airplay = with types; {
    enable = mkBoolOpt false "Whether or not to enable AirPlay support with uxplay.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      uxplay
    ];
  };
}