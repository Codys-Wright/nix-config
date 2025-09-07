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
  cfg = config.${namespace}.services.remote-desktop.moonlight;
in
{
  options.${namespace}.services.remote-desktop.moonlight = with types; {
    enable = mkBoolOpt false "Enable Moonlight (Game streaming client)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      moonlight-qt
    ];
  };
}
