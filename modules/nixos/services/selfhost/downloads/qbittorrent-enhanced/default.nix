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
  cfg = config.${namespace}.services.selfhost.downloads.qbittorrent-enhanced;
  selfhostCfg = config.${namespace}.services.selfhost;
  wireguardCfg = config.${namespace}.services.selfhost.networking.wireguard-netns;
in
{
  options.${namespace}.services.selfhost.downloads.qbittorrent-enhanced = with types; {
    enable = mkBoolOpt false "Enable qBittorrent Enhanced torrent client (can be bound to VPN)";
    
    configDir = mkOpt str "/var/lib/qbittorrent" "Configuration directory for qBittorrent";
    
    url = mkOpt str "qbittorrent.${selfhostCfg.baseDomain}" "URL for qBittorrent service";
    
    homepage = {
      name = mkOpt str "qBittorrent Enhanced" "Name shown on homepage";
      description = mkOpt str "Enhanced torrent client" "Description shown on homepage";
      icon = mkOpt str "qbittorrent.svg" "Icon shown on homepage";
      category = mkOpt str "Downloads" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    # qBittorrent Enhanced service configuration
    services.qbittorrent = {
      enable = true;
      package = pkgs.qbittorrent-enhanced-nox;
      user = selfhostCfg.user;
      group = selfhostCfg.group;
      webuiPort = 8081;
      openFirewall = false; # We'll handle this through Caddy
    };

    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8081
      '';
    };

    # Optional VPN network namespace integration
    systemd = mkIf wireguardCfg.enable {
      services.qbittorrent.bindsTo = [ "netns@${wireguardCfg.namespace}.service" ];
      services.qbittorrent.requires = [
        "network-online.target"
        "${wireguardCfg.namespace}.service"
      ];
      services.qbittorrent.serviceConfig.NetworkNamespacePath = [ "/var/run/netns/${wireguardCfg.namespace}" ];
      
      sockets."qbittorrent-proxy" = {
        enable = true;
        description = "Socket for Proxy to qBittorrent WebUI";
        listenStreams = [ "8081" ];
        wantedBy = [ "sockets.target" ];
      };
      
      services."qbittorrent-proxy" = {
        enable = true;
        description = "Proxy to qBittorrent in Network Namespace";
        requires = [
          "qbittorrent.service"
          "qbittorrent-proxy.socket"
        ];
        after = [
          "qbittorrent.service"
          "qbittorrent-proxy.socket"
        ];
        unitConfig = {
          JoinsNamespaceOf = "qbittorrent.service";
        };
        serviceConfig = {
          User = config.services.qbittorrent.user;
          Group = config.services.qbittorrent.group;
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:8081";
          PrivateNetwork = "yes";
        };
      };
    };
  };
}
