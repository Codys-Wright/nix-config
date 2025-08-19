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
  cfg = config.${namespace}.services.selfhost.utility;
in
{
  options.${namespace}.services.selfhost.utility = with types; {
    enable = mkBoolOpt false "Enable utility services";
  };

  config = mkIf cfg.enable {
    ${namespace}.services.selfhost.utility = {
      grafana.enable = mkDefault true;
      ollama.enable = mkDefault true;
      stirling-pdf.enable = mkDefault true;
      uptime-kuma.enable = mkDefault true;
      microbin.enable = mkDefault true;
      keycloak.enable = mkDefault true;
      fail2ban-cloudflare.enable = mkDefault true;
    };
  };
} 