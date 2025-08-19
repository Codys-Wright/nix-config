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
  cfg = config.${namespace}.services.selfhost.networking.wireguard-netns;
  selfhostCfg = config.${namespace}.services.selfhost;
in
{
  options.${namespace}.services.selfhost.networking.wireguard-netns = with types; {
    enable = mkBoolOpt false "Enable Wireguard client network namespace";
    
    namespace = mkOpt str "wg_client" "Network namespace name";
    
    configFile = mkOpt (nullOr path) null "Path to Wireguard config file (not wg-quick format)";
    
    privateIP = mkOpt str "" "Private IP address for the Wireguard interface";
    
    dnsIP = mkOpt str "1.1.1.1" "DNS server IP for the namespace";
  };

  config = mkIf (cfg.enable && cfg.configFile != null) {
    # Generic network namespace service
    systemd.services."netns@" = {
      description = "%I network namespace";
      before = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
        ExecStop = "${pkgs.iproute2}/bin/ip netns del %I";
      };
    };
    
    # DNS configuration for the namespace
    environment.etc."netns/${cfg.namespace}/resolv.conf".text = "nameserver ${cfg.dnsIP}";

    # Wireguard network interface service
    systemd.services.${cfg.namespace} = {
      description = "${cfg.namespace} network interface";
      bindsTo = [ "netns@${cfg.namespace}.service" ];
      requires = [ "network-online.target" ];
      after = [ "netns@${cfg.namespace}.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = with pkgs; writers.writeBash "wg-up" ''
          set -e
          ${iproute2}/bin/ip link add wg0 type wireguard
          ${iproute2}/bin/ip link set wg0 netns ${cfg.namespace}
          ${iproute2}/bin/ip -n ${cfg.namespace} address add ${cfg.privateIP} dev wg0
          ${iproute2}/bin/ip netns exec ${cfg.namespace} \
          ${wireguard-tools}/bin/wg setconf wg0 ${cfg.configFile}
          ${iproute2}/bin/ip -n ${cfg.namespace} link set wg0 up
          ${iproute2}/bin/ip -n ${cfg.namespace} link set lo up
          ${iproute2}/bin/ip -n ${cfg.namespace} route add default dev wg0
        '';
        ExecStop = with pkgs; writers.writeBash "wg-down" ''
          set -e
          ${iproute2}/bin/ip -n ${cfg.namespace} route del default dev wg0
          ${iproute2}/bin/ip -n ${cfg.namespace} link del wg0
        '';
      };
    };
  };
} 