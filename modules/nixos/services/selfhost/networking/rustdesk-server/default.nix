
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
  cfg = config.${namespace}.services.selfhost.networking.rustdesk-server;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.networking.rustdesk-server = with types; {
    enable = mkBoolOpt false "Enable RustDesk Server (remote desktop)";
    
    relayIP = mkOpt str "" "Public IP for the relay server (leave empty for auto-detect)";
    
    homepage = {
      name = mkOpt str "RustDesk" "Name shown on homepage";
      description = mkOpt str "Self-hosted remote desktop server" "Description shown on homepage";
      icon = mkOpt str "rustdesk.svg" "Icon shown on homepage";
      category = mkOpt str "Networking" "Category on homepage";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      rustdesk-server
    ];

    services.rustdesk-server = {
      enable = true;
      openFirewall = true;
      relayIP = mkIf (cfg.relayIP != "") cfg.relayIP;
    };

    # Create directory for rustdesk data
    systemd.tmpfiles.rules = [
      "d /var/lib/rustdesk-server 0755 rustdesk-server rustdesk-server - -"
    ];
  };
}
