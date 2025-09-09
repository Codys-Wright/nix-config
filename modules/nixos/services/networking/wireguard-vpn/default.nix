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
  cfg = config.${namespace}.services.networking.wireguard-vpn;
in
{
  options.${namespace}.services.networking.wireguard-vpn = with types; {
    enable = mkBoolOpt false "Enable WireGuard VPN client";

    interface = mkOpt str "wg0" "WireGuard interface name";
    
    privateKeyFile = mkOpt str "/etc/wireguard/wg0.key" "Path to private key file";
    
    address = mkOpt (listOf str) [] "IP addresses for this interface";
    
    dns = mkOpt (listOf str) [] "DNS servers to use";
    
    peers = mkOpt (listOf (submodule {
      options = {
        publicKey = mkOpt str "" "Public key of the peer";
        allowedIPs = mkOpt (listOf str) [] "Allowed IP ranges";
        endpoint = mkOpt str "" "Peer endpoint (IP:port)";
        persistentKeepalive = mkOpt int 25 "Keepalive interval in seconds";
      };
    })) [] "WireGuard peers";
    
    killswitch = {
      enable = mkBoolOpt true "Enable killswitch to block traffic when VPN is down";
      allowedSubnets = mkOpt (listOf str) [ "192.168.0.0/16" "10.0.0.0/8" ] "Subnets to allow without VPN";
    };
    
    firewall = {
      enable = mkBoolOpt true "Open firewall ports for WireGuard";
      listenPort = mkOpt port 51820 "Local listen port for WireGuard";
    };
  };

  config = mkIf cfg.enable {
    # Enable WireGuard kernel module
    boot.kernelModules = [ "wireguard" ];

    # Configure WireGuard interface using wg-quick
    networking.wg-quick.interfaces.${cfg.interface} = {
      address = cfg.address;
      dns = cfg.dns;
      privateKeyFile = cfg.privateKeyFile;
      peers = cfg.peers;
      
      # Killswitch implementation
      postUp = mkIf cfg.killswitch.enable ''
        # Mark packets on the ${cfg.interface} interface
        wg set ${cfg.interface} fwmark ${toString cfg.firewall.listenPort}

        # Forbid anything else which doesn't go through wireguard VPN on IPv4
        ${pkgs.iptables}/bin/iptables -A OUTPUT \
          ${concatMapStringsSep " " (subnet: "! -d ${subnet} \\") cfg.killswitch.allowedSubnets}
          ! -o ${cfg.interface} \
          -m mark ! --mark $(wg show ${cfg.interface} fwmark) \
          -m addrtype ! --dst-type LOCAL \
          -j REJECT

        # Forbid anything else which doesn't go through wireguard VPN on IPv6
        ${pkgs.iptables}/bin/ip6tables -A OUTPUT \
          ! -o ${cfg.interface} \
          -m mark ! --mark $(wg show ${cfg.interface} fwmark) \
          -m addrtype ! --dst-type LOCAL \
          -j REJECT
      '';

      postDown = mkIf cfg.killswitch.enable ''
        # Remove killswitch rules
        ${pkgs.iptables}/bin/iptables -D OUTPUT \
          ${concatMapStringsSep " " (subnet: "! -d ${subnet} \\") cfg.killswitch.allowedSubnets}
          ! -o ${cfg.interface} \
          -m mark ! --mark $(wg show ${cfg.interface} fwmark) \
          -m addrtype ! --dst-type LOCAL \
          -j REJECT || true

        ${pkgs.iptables}/bin/ip6tables -D OUTPUT \
          ! -o ${cfg.interface} \
          -m mark ! --mark $(wg show ${cfg.interface} fwmark) \
          -m addrtype ! --dst-type LOCAL \
          -j REJECT || true
      '';
    };

    # Firewall configuration
    networking.firewall = mkIf cfg.firewall.enable {
      allowedUDPPorts = [ cfg.firewall.listenPort ];
    };

    # Ensure the private key file exists and has proper permissions
    systemd.tmpfiles.rules = [
      "f /etc/wireguard/wg0.key 0400 root root - -"
    ];

    # Add WireGuard tools to system packages
    environment.systemPackages = with pkgs; [
      wireguard-tools
    ];
  };
}
