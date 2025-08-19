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
  cfg = config.${namespace}.services.selfhost.productivity;
in
{
  options.${namespace}.services.selfhost.productivity = with types; {
    enable = mkBoolOpt false "Enable productivity services";
  };

  config = mkIf cfg.enable {
    ${namespace}.services.selfhost.productivity = {
      mealie.enable = mkDefault true;
      calibre.enable = mkDefault true;
      firefly-iii.enable = mkDefault false;
      wanderer.enable = mkDefault false;
      vaultwarden.enable = mkDefault false;
      paperless-ngx.enable = mkDefault false;
      miniflux.enable = mkDefault false;
      radicale.enable = mkDefault true;
    };
  };
} 