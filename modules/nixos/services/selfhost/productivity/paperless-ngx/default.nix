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
  cfg = config.${namespace}.services.selfhost.productivity.paperless-ngx;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.productivity.paperless-ngx = with types; {
    enable = mkBoolOpt false "Enable Paperless-ngx (document management)";
    
    mediaDir = mkOpt str "${selfhostCfg.mounts.fast}/Documents/Paperless/Documents" "Directory for storing documents";
    
    consumptionDir = mkOpt str "${selfhostCfg.mounts.fast}/Documents/Paperless/Import" "Directory for importing documents";
    
    passwordFile = mkOpt path "" "Path to file containing admin password";
    
    configDir = mkOpt str "/var/lib/paperless" "Configuration directory";
    
    url = mkOpt str "paperless.${selfhostCfg.baseDomain}" "URL for Paperless-ngx service";
    
    homepage = {
      name = mkOpt str "Paperless-ngx" "Name shown on homepage";
      description = mkOpt str "Document management system" "Description shown on homepage";
      icon = mkOpt str "paperless.svg" "Icon shown on homepage";
      category = mkOpt str "Productivity" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.paperless = {
      enable = true;
      passwordFile = cfg.passwordFile;
      user = selfhostCfg.user;
      mediaDir = cfg.mediaDir;
      consumptionDir = cfg.consumptionDir;
      consumptionDirIsPublic = true;
      
      settings = {
        PAPERLESS_URL = "https://${cfg.url}";
        PAPERLESS_CONSUMER_IGNORE_PATTERN = [
          ".DS_STORE/*"
          "desktop.ini"
        ];
        PAPERLESS_OCR_LANGUAGE = "deu+eng";
        PAPERLESS_OCR_USER_ARGS = {
          optimize = 1;
          pdfa_image_compression = "lossless";
        };
      };
    };
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:${toString config.services.paperless.port}
      '';
    };
  };
} 