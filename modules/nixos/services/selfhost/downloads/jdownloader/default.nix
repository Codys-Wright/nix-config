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
  cfg = config.${namespace}.services.selfhost.downloads.jdownloader;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.downloads.jdownloader = with types; {
    enable = mkBoolOpt false "Enable JDownloader 2 download manager";
    
    configDir = mkOpt str "/var/lib/jdownloader" "Configuration directory for JDownloader";
    
    downloadsDir = mkOpt str "/var/lib/jdownloader/downloads" "Downloads directory for JDownloader";
    
    url = mkOpt str "jdownloader.${selfhostCfg.baseDomain}" "URL for JDownloader service";
    
    cloudflare-tunnel = mkBoolOpt false "Include JDownloader in Cloudflare tunnel (may cause conflicts with OCI containers)";
    
    homepage = {
      name = mkOpt str "JDownloader 2" "Name shown on homepage";
      description = mkOpt str "Download manager with web interface" "Description shown on homepage";
      icon = mkOpt str "jdownloader.svg" "Icon shown on homepage";
      category = mkOpt str "Downloads" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    # Create directories
    systemd.tmpfiles.rules = [
      "d ${cfg.configDir} 0755 ${selfhostCfg.user} ${selfhostCfg.group} - -"
      "d ${cfg.downloadsDir} 0755 ${selfhostCfg.user} ${selfhostCfg.group} - -"
    ];

    # JDownloader OCI container with VNC web interface
    virtualisation.oci-containers.containers.jdownloader-2 = {
      image = "jlesage/jdownloader-2:latest";
      autoStart = true;
      extraOptions = [
        "--pull=newer"
      ];
      
      ports = [ "5800:5800" ];
      
      volumes = [
        "${cfg.configDir}:/config:rw"
        "${cfg.downloadsDir}:/output:rw"
      ];
      
      environment = {
        # Enable web audio for better experience
        WEB_AUDIO = "1";
        # Enable file manager
        FILE_MANAGER = "1";
        # VNC/web authentication (optional - can be set via web interface)
        VNC_PASSWORD = "";
        WEB_AUTH = "false";
      };
    };

    # Caddy reverse proxy for VNC web interface
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:5800 {
          header_up Host {host}
          header_up X-Real-IP {remote}
          header_up X-Forwarded-For {remote}
          header_up X-Forwarded-Proto {scheme}
        }
        
        # WebSocket support for VNC
        reverse_proxy /websockify http://127.0.0.1:5800 {
          header_up Host {host}
          header_up X-Real-IP {remote}
          header_up X-Forwarded-For {remote}
          header_up X-Forwarded-Proto {scheme}
          header_up Upgrade {>Upgrade}
          header_up Connection {>Connection}
        }
        
        # WebSocket support for audio
        reverse_proxy /websockify-audio http://127.0.0.1:5800 {
          header_up Host {host}
          header_up X-Real-IP {remote}
          header_up X-Forwarded-For {remote}
          header_up X-Forwarded-Proto {scheme}
          header_up Upgrade {>Upgrade}
          header_up Connection {>Connection}
        }
      '';
    };
  };
}
