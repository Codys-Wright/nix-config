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
  cfg = config.${namespace}.services.selfhost.downloads.deluge;
  selfhostCfg = config.${namespace}.services.selfhost;
  wireguardCfg = config.${namespace}.services.selfhost.networking.wireguard-netns;
in
{
  options.${namespace}.services.selfhost.downloads.deluge = with types; {
    enable = mkBoolOpt false "Enable Deluge torrent client (can be bound to VPN)";
    
    configDir = mkOpt str "/var/lib/deluge" "Configuration directory for Deluge";
    
    url = mkOpt str "deluge.${selfhostCfg.baseDomain}" "URL for Deluge service";
    
    homepage = {
      name = mkOpt str "Deluge" "Name shown on homepage";
      description = mkOpt str "Torrent client" "Description shown on homepage";
      icon = mkOpt str "deluge.svg" "Icon shown on homepage";
      category = mkOpt str "Downloads" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    services.deluge = {
      enable = true;
      user = selfhostCfg.user;
      group = selfhostCfg.group;
      web = {
        enable = true;
      };
    };

    # Caddy reverse proxy
    services.caddy.virtualHosts."${cfg.url}" = mkIf (selfhostCfg.baseDomain != "") {
      useACMEHost = selfhostCfg.baseDomain;
      extraConfig = ''
        reverse_proxy http://127.0.0.1:8112
      '';
    };

    # Optional VPN network namespace integration
    systemd = mkIf wireguardCfg.enable {
      services.deluged.bindsTo = [ "netns@${wireguardCfg.namespace}.service" ];
      services.deluged.requires = [
        "network-online.target"
        "${wireguardCfg.namespace}.service"
      ];
      services.deluged.serviceConfig.NetworkNamespacePath = [ "/var/run/netns/${wireguardCfg.namespace}" ];
      
      sockets."deluged-proxy" = {
        enable = true;
        description = "Socket for Proxy to Deluge WebUI";
        listenStreams = [ "58846" ];
        wantedBy = [ "sockets.target" ];
      };
      
      services."deluged-proxy" = {
        enable = true;
        description = "Proxy to Deluge Daemon in Network Namespace";
        requires = [
          "deluged.service"
          "deluged-proxy.socket"
        ];
        after = [
          "deluged.service"
          "deluged-proxy.socket"
        ];
        unitConfig = {
          JoinsNamespaceOf = "deluged.service";
        };
        serviceConfig = {
          User = config.services.deluge.user;
          Group = config.services.deluge.group;
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:58846";
          PrivateNetwork = "yes";
        };
      };
    };
  };
} 