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
  cfg = config.${namespace}.services.flatpak;
in
{
  options.${namespace}.services.flatpak = with types; {
    enable = mkBoolOpt false "Enable Flatpak service and support";
  };

  config = mkIf cfg.enable {
    services.flatpak.enable = true;
  };
}
