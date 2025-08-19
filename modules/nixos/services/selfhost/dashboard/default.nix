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
  cfg = config.${namespace}.services.selfhost.dashboard;
in
{
  options.${namespace}.services.selfhost.dashboard = with types; {
    enable = mkBoolOpt false "Enable dashboard services";
  };

  config = mkIf cfg.enable {
    ${namespace}.services.selfhost.dashboard = {
      homepage.enable = mkDefault true;
    };
  };
} 