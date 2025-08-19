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
in
{
  options.${namespace}.services.selfhost.cloud.nextcloud = with types; {
    enable = mkBoolOpt false "Enable nextcloud";
  };

  config = mkIf cfg.enable {
    sops.secrets.nextcloud-admin = {
      owner = "nextcloud";
      group = "nextcloud";
    };

    fileSystems."/var/lib/nextcloud" = {
      device = "/mnt/data/nextcloud";
      options = [ "bind" ];
    };

    services.nextcloud = {
      enable = true;
      configureRedis = true;
      package = pkgs.nextcloud31;
      hostName = "apollo.nextcloud.home";
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
        adminpassFile = config.sops.secrets.nextcloud-admin.path;
        adminuser = "admin";
      };
      settings = {
        trusted_domains = [
          "localhost"
          "127.0.0.1"
          "100.123.33.43"
          "apollo"
        ];

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

    #services.postgresqlBackup = {
    #      enable = true;
    #      startAt = "*-*-* 01:15:00";
    #    };

    services.nginx.virtualHosts.${config.services.nextcloud.hostName}.listen = [
      {
        addr = "0.0.0.0";
        port = 8081;
      }
    ];
  };
}
