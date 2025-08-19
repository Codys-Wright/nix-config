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
  cfg = config.${namespace}.services.selfhost.cloud.nextcloud;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.cloud.nextcloud = with types; {
    enable = mkBoolOpt false "Enable Nextcloud (cloud storage and collaboration)";
    
    dataDir = mkOpt str "/mnt/data/nextcloud" "Data directory for Nextcloud";
    
    url = mkOpt str "nextcloud.${selfhostCfg.baseDomain}" "URL for Nextcloud service";
    
    adminPasswordFile = mkOpt path "" "File containing admin password";
    
    homepage = {
      name = mkOpt str "Nextcloud" "Name shown on homepage";
      description = mkOpt str "Cloud storage and collaboration platform" "Description shown on homepage";
      icon = mkOpt str "nextcloud.svg" "Icon shown on homepage";
      category = mkOpt str "Cloud" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    # Optional SOPS secrets for admin password
    sops.secrets.nextcloud-admin = mkIf (cfg.adminPasswordFile == "") {
      owner = "nextcloud";
      group = "nextcloud";
    };

    # Mount data directory
    fileSystems."/var/lib/nextcloud" = {
      device = cfg.dataDir;
      options = [ "bind" ];
    };

    services.nextcloud = {
      enable = true;
      configureRedis = true;
      package = pkgs.nextcloud31;
      hostName = cfg.url;
      home = "/var/lib/nextcloud";
      database.createLocally = true;
      
      extraApps = {
        inherit (config.services.nextcloud.package.packages.apps)
          contacts
          calendar
          cookbook
          tasks
          onlyoffice
          news
          notes
          ;
      };
      extraAppsEnable = true;
      autoUpdateApps.enable = true;

      config = {
        dbtype = "pgsql";
        adminpassFile = if cfg.adminPasswordFile != "" then cfg.adminPasswordFile else config.sops.secrets.nextcloud-admin.path;
        adminuser = "admin";
      };
      
      settings = {
        trusted_domains = [
          cfg.url
          "localhost"
          "127.0.0.1"
        ];
        
        overwriteprotocol = "https";
        overwrite.cli.url = "https://${cfg.url}";

        enabledPreviewProviders = [
          "OC\\Preview\\BMP"
          "OC\\Preview\\GIF"
          "OC\\Preview\\JPEG"
          "OC\\Preview\\Krita"
          "OC\\Preview\\MarkDown"
          "OC\\Preview\\MP3"
          "OC\\Preview\\OpenDocument"
          "OC\\Preview\\PNG"
          "OC\\Preview\\TXT"
          "OC\\Preview\\XBitmap"
          "OC\\Preview\\HEIC"
        ];
      };
      maxUploadSize = "10G";
    };

    # Configure nginx to listen on localhost only
    services.nginx.virtualHosts.${cfg.url}.listen = [
      {
        addr = "127.0.0.1";
        port = 8081;
      }
    ];
    
    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8081
      '';
    };

    # Optional PostgreSQL backup
    # services.postgresqlBackup = {
    #   enable = true;
    #   startAt = "*-*-* 01:15:00";
    # };
  };
}
