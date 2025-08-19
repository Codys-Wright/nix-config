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
  cfg = config.${namespace}.services.selfhost.productivity.calibre;
  selfhostCfg = config.${namespace}.services.selfhost;
  library = "/var/lib/calibre-server";
in
{
  options.${namespace}.services.selfhost.productivity.calibre = with types; {
    enable = mkBoolOpt false "Enable Calibre (ebook management)";
    
    libraryPath = mkOpt str "/mnt/data/calibre" "Path to Calibre library";
    
    url = mkOpt str "books.${selfhostCfg.baseDomain}" "URL for Calibre Web interface";
    
    homepage = {
      name = mkOpt str "Calibre" "Name shown on homepage";
      description = mkOpt str "Ebook library management" "Description shown on homepage";
      icon = mkOpt str "calibre.svg" "Icon shown on homepage";
      category = mkOpt str "Productivity" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    # Mount library directory
    fileSystems."/var/lib/calibre-server" = {
      device = cfg.libraryPath;
      options = [ "bind" ];
    };
    
    services = {
      calibre-server = {
        enable = true;
        host = "127.0.0.1";
        port = 8195;
        libraries = [ library ];
        auth.enable = false;
        user = selfhostCfg.user;
        group = selfhostCfg.group;
      };
      
      calibre-web = {
        enable = true;
        listen = {
          ip = "127.0.0.1";
          port = 8095;
        };
        options = {
          enableBookConversion = true;
          enableBookUploading = true;
          reverseProxyAuth.enable = true;
          calibreLibrary = "/var/lib/calibre-server";
        };
        user = selfhostCfg.user;
        group = selfhostCfg.group;
      };
    };

    # Caddy reverse proxy for Calibre Web
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8095
      '';
    };

    systemd.services.calibre-web.after = [ "calibre-server.service" ];
  };
}

