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
  cfg = config.${namespace}.hardware.audio.raysession;
in
{
  options.${namespace}.hardware.audio.raysession = with types; {
    enable = mkBoolOpt false "Enable raysession audio session manager";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      stable.raysession
      python313Packages.legacy-cgi
    ];
  };
} 