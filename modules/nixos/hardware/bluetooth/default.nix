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
  cfg = config.${namespace}.hardware.bluetooth;
in
{
  options.${namespace}.hardware.bluetooth = with types; {
    enable = mkBoolOpt false "Enable bluetooth";
  };

  config = mkIf cfg.enable {
    hardware.bluetooth = {
      enable = true;
      package = pkgs.bluez;
      powerOnBoot = true;
    };

    services.blueman.enable = true;
  };
}
