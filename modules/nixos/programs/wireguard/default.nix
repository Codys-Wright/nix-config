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
  cfg = config.${namespace}.programs.wireguard;
in
{
  options.${namespace}.programs.wireguard = with types; {
    enable = mkBoolOpt false "Enable WireGuard tools and web UI";
    
    webUI = {
      enable = mkBoolOpt true "Enable WireGuard web UI";
      port = mkOpt port 8080 "Port for WireGuard web UI";
      host = mkOpt str "localhost" "Host for WireGuard web UI";
    };
    
    tools = {
      enable = mkBoolOpt true "Enable WireGuard command line tools";
      netmanager = mkBoolOpt true "Enable wg-netmanager";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # Core WireGuard tools
      wireguard-tools
    ] ++ lib.optionals cfg.tools.enable [
      # Additional tools
      wireguard-go
    ] ++ lib.optionals cfg.tools.netmanager [
      # Network manager
      wg-netmanager
    ] ++ lib.optionals cfg.webUI.enable [
      # Web UI
      wireguard-ui
    ];

    # Enable WireGuard kernel module
    boot.kernelModules = [ "wireguard" ];

    # Create systemd service for WireGuard UI if enabled
    systemd.services.wireguard-ui = mkIf cfg.webUI.enable {
      description = "WireGuard Web UI";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      
      serviceConfig = {
        Type = "simple";
        User = "wireguard-ui";
        Group = "wireguard-ui";
        ExecStart = "${pkgs.wireguard-ui}/bin/wireguard-ui";
        Restart = "always";
        RestartSec = 5;
        WorkingDirectory = "/var/lib/wireguard-ui";
        
        # Security settings
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ReadWritePaths = [ "/var/lib/wireguard-ui" "/etc/wireguard" ];
      };
    };

    # Create user and group for WireGuard UI
    users.users.wireguard-ui = mkIf cfg.webUI.enable {
      isSystemUser = true;
      group = "wireguard-ui";
      home = "/var/lib/wireguard-ui";
      createHome = true;
    };

    users.groups.wireguard-ui = mkIf cfg.webUI.enable {};

    # Create directories
    systemd.tmpfiles.rules = mkIf cfg.webUI.enable [
      "d /var/lib/wireguard-ui 0755 wireguard-ui wireguard-ui - -"
      "d /etc/wireguard 0755 root root - -"
    ];

    # Firewall rules for web UI
    networking.firewall = mkIf cfg.webUI.enable {
      allowedTCPPorts = [ cfg.webUI.port ];
    };
  };
}
