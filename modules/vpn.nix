# Standalone VPN Module
# ProtonVPN OpenVPN configuration for any NixOS host
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.myModules.vpn;
in
{
  options.myModules.vpn = {
    enable = lib.mkEnableOption "ProtonVPN OpenVPN client";

    username = lib.mkOption {
      type = lib.types.str;
      description = "ProtonVPN username";
      example = "your_protonvpn_username";
    };

    passwordFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to file containing ProtonVPN password";
      example = "/run/secrets/protonvpn-password";
    };

    killswitch = {
      enable = lib.mkEnableOption "VPN kill switch";

      allowedSubnets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "192.168.0.0/16" "10.0.0.0/8" ];
        description = "Local subnets to allow when VPN is active";
      };

      exemptPorts = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [ 22 ];
        description = "Ports to exempt from kill switch";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Required packages
    environment.systemPackages = with pkgs; [
      openvpn
      cifs-utils  # For SMB if needed
    ];

    # ProtonVPN OpenVPN configuration
    services.openvpn.servers.protonvpn = {
      config = ''
        client
        dev tun
        proto tcp

        # ProtonVPN servers with failover
        remote-random
        remote 149.40.62.62 8443
        remote 146.70.84.2 7770
        remote 149.40.51.233 7770
        remote 95.173.221.65 443
        remote 68.169.42.240 7770
        remote 89.222.100.66 8443
        remote 79.127.187.185 8443
        remote 138.199.35.97 8443
        remote 95.173.217.217 443
        remote 149.102.242.59 443
        remote 146.70.72.130 7770
        remote 68.169.42.240 8443
        remote 79.127.187.185 443
        remote 79.127.136.222 8443
        remote 79.127.187.185 7770
        remote 87.249.134.138 8443
        remote 79.127.160.129 443
        remote 89.187.175.129 443
        remote 87.249.134.138 443
        remote 79.127.136.222 443
        remote 79.127.185.166 443
        remote 95.173.221.65 7770
        remote 146.70.72.130 443
        remote 79.127.185.166 7770
        remote 163.5.171.83 7770
        remote 138.199.35.97 443
        remote 79.127.160.187 7770
        remote 89.187.175.132 8443
        remote 163.5.171.83 8443
        remote 89.222.100.66 7770
        remote 89.187.175.132 443
        remote 146.70.84.2 443
        remote 149.22.80.1 443
        remote 87.249.134.138 7770
        remote 149.22.80.1 7770
        remote 79.127.185.166 8443
        remote 79.127.160.187 443
        remote 149.40.51.233 8443
        remote 138.199.35.97 7770
        remote 149.40.62.62 443
        remote 95.173.221.65 8443
        remote 149.102.242.59 8443
        remote 163.5.171.83 443
        remote 149.40.51.226 7770
        remote 89.222.100.66 443
        remote 79.127.160.187 8443
        remote 89.187.175.129 8443
        remote 149.40.51.233 443
        remote 146.70.72.130 8443
        remote 79.127.160.129 8443
        remote 149.40.62.62 7770
        remote 95.173.217.217 8443
        remote 95.173.217.217 7770
        remote 149.102.242.59 7770
        remote 79.127.136.222 7770
        remote 79.127.160.129 7770
        remote 149.40.51.226 443
        remote 149.22.80.1 8443
        remote 149.40.51.226 8443
        remote 146.70.84.2 8443
        remote 89.187.175.132 7770
        remote 89.187.175.129 7770
        remote 68.169.42.240 443

        server-poll-timeout 20
        resolv-retry infinite
        nobind
        persist-key
        persist-tun

        cipher AES-256-GCM
        setenv CLIENT_CERT 0
        tun-mtu 1500
        mssfix 0
        reneg-sec 0

        remote-cert-tls server
        auth-user-pass ${cfg.passwordFile}

        verb 3

        status /tmp/openvpn/protonvpn.status

        script-security 2
      '';

      autoStart = true;
      updateResolvConf = true;
    };

    # Kill switch implementation
    networking.firewall.extraCommands = lib.mkIf cfg.killswitch.enable ''
      # VPN Kill Switch: Block all OUTPUT except VPN, loopback, and allowed traffic

      # Allow loopback
      iptables -A nixos-fw -o lo -j ACCEPT

      # Allow VPN interface (tun0)
      iptables -A nixos-fw -o tun0 -j ACCEPT

      # Allow established connections
      iptables -A nixos-fw -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

      # Allow traffic to allowed subnets
      ${lib.concatMapStrings (subnet: ''
        iptables -A nixos-fw -d ${subnet} -j ACCEPT
      '') cfg.killswitch.allowedSubnets}

      # Allow exempt ports
      ${lib.concatMapStrings (port: ''
        iptables -A nixos-fw -p tcp --dport ${toString port} -j ACCEPT
        iptables -A nixos-fw -p udp --dport ${toString port} -j ACCEPT
      '') cfg.killswitch.exemptPorts}

      # Block everything else
      iptables -A nixos-fw -j DROP
    '';

    # OpenVPN needs permissions to read the password file
    systemd.services.openvpn-protonvpn.serviceConfig.SupplementaryGroups = [ "keys" ];
  };
}