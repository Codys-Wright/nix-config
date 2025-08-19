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
      firefly-iii.enable = mkDefault true;
      wanderer.enable = mkDefault true;
      vaultwarden.enable = mkDefault true;
      paperless-ngx.enable = mkDefault true;
      miniflux.enable = mkDefault true;
      radicale.enable = mkDefault true;
    };
  };
} 