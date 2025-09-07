
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

    publicKey = mkOpt str "" "Public key for RustDesk server authentication";
    privateKey = mkOpt str "" "Private key for RustDesk server authentication";

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
      signal.enable = true;
      relay.enable = true;
      signal.relayHosts = if selfhostCfg.systemIp != "" then [ selfhostCfg.systemIp ] else [ "127.0.0.1" ];
    };

    # Create directory for rustdesk data
    systemd.tmpfiles.rules = [
      "d /var/lib/rustdesk-server 0755 rustdesk-server rustdesk-server - -"
    ];
  };
}
