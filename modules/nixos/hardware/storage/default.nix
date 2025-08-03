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
  cfg = config.${namespace}.hardware.storage;
in
{
  options.${namespace}.hardware.storage = with types; {
    enable = mkBoolOpt false "Enable automatic storage mounting";
  };

  config = mkIf cfg.enable {
    # Enable automatic mounting of external and internal hard drives
    services.udisks2.enable = true;
    services.gvfs.enable = true;
    services.devmon.enable = true;
  };
} 