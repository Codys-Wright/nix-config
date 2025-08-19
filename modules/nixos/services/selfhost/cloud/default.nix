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
  cfg = config.${namespace}.services.selfhost.cloud;
in
{
  options.${namespace}.services.selfhost.cloud = with types; {
    enable = mkBoolOpt false "Enable cloud services";
  };

  config = mkIf cfg.enable {
    ${namespace}.services.selfhost.cloud = {
      immich.enable = mkDefault true;
      nextcloud.enable = mkDefault false;
      ocis.enable = mkDefault true;
    };
  };
} 