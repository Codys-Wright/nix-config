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
  cfg = config.${namespace}.services.selfhost.smarthome;
in
{
  options.${namespace}.services.selfhost.smarthome = with types; {
    enable = mkBoolOpt false "Enable smart home services";
  };

  config = mkIf cfg.enable {
    ${namespace}.services.selfhost.smarthome = {
      homeassistant.enable = mkDefault true;
    };
  };
} 