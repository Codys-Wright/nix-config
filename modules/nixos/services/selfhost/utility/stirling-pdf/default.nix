{
  options,
  config,
  lib,
  pkgs,
  namespace,
  inputs,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.${namespace}.services.selfhost.utility.stirling-pdf;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.utility.stirling-pdf = with types; {
    enable = mkBoolOpt false "Enable Stirling PDF (PDF tools)";
    
    url = mkOpt str "pdf.${selfhostCfg.baseDomain}" "URL for Stirling PDF service";
    
    homepage = {
      name = mkOpt str "Stirling PDF" "Name shown on homepage";
      description = mkOpt str "Locally hosted web application for PDF manipulation" "Description shown on homepage";
      icon = mkOpt str "stirling-pdf.svg" "Icon shown on homepage";
      category = mkOpt str "Utility" "Category on homepage";
    };
  };

  # disabledModules = [ "services/web-apps/stirling-pdf.nix" ];
  # imports = [ "${inputs.unstable}/nixos/modules/services/web-apps/stirling-pdf.nix" ];

  config = mkIf cfg.enable {
    services.stirling-pdf = {
      enable = true;
      environment = {
        SERVER_PORT = 8001;
        INSTALL_BOOK_AND_ADVANCED_HTML_OPS = "false";
        LANGS = "en_US";
      };
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8001
      '';
    };
  };
}
