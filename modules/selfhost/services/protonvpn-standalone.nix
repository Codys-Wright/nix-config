# ProtonVPN - OpenVPN client with kill switch
{
  FTS,
  inputs,
  lib,
  ...
}: {
  FTS.selfhost._.protonvpn-standalone = {
    # Required parameters
    usernameFile,
    passwordFile,
    # Optional parameters
    killswitch ? {
      enable = true;
      allowedSubnets = ["192.168.0.0/16" "10.0.0.0/8"];
      exemptPorts = [22];
    },
    dev ? "tun0",
    ...
  } @ args: {
    class,
    aspect-chain,
  }: {
    description = ''
      ProtonVPN Standalone - OpenVPN client with kill switch for desktop systems.

      Features:
      - ProtonVPN OpenVPN configuration with 64+ servers
      - Automatic failover across multiple ProtonVPN servers
      - Configurable kill switch to prevent leaks
      - Local network access preservation
      - Secure credential management

       Configuration:
       - Username file: ${usernameFile}
       - Password file: ${passwordFile}
       - Kill switch: ${
        if killswitch.enable
        then "enabled"
        else "disabled"
      }
      - Device: ${dev}
      - Allowed subnets: ${lib.concatStringsSep ", " killswitch.allowedSubnets}
    '';

    nixos = {
      config,
      lib,
      pkgs,
      ...
    }: {
      # ProtonVPN OpenVPN configuration
      services.openvpn.servers.protonvpn = {
        config = ''
          client
          dev ${dev}
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
          auth-user-pass /run/openvpn/protonvpn.auth

          verb 3

          status /tmp/openvpn/protonvpn.status

          script-security 2

          <ca>
          -----BEGIN CERTIFICATE-----
          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
          EA==
          -----END CERTIFICATE-----
          </ca>

          <tls-crypt>
          -----BEGIN OpenVPN Static key V1-----
          6acef03f62675b4b1bbd03e53b187727
          423cea742242106cb2916a8a4c829756
          3d22c7e5cef430b1103c6f66eb1fc5b3
          75a672f158e2e2e936c3faa48b035a6d
          e17beaac23b5f03b10b868d53d03521d
          8ba115059da777a60cbfd7b2c9c57472
          78a15b8f6e68a3ef7fd583ec9f398c8b
          d4735dab40cbd1e3c62a822e97489186
          c30a0b48c7c38ea32ceb056d3fa5a710
          e10ccc7a0ddb363b08c3d2777a3395e1
          0c0b6080f56309192ab5aacd4b45f55d
          a61fc77af39bd81a19218a79762c3386
          2df55785075f37d8c71dc8a42097ee43
          344739a0dd48d03025b0450cf1fb5e8c
          aeb893d9a96d1f15519bb3c4dcb40ee3
          16672ea16c012664f8a9f11255518deb
          -----END OpenVPN Static key V1-----
          </tls-crypt>
        '';

        autoStart = true;
        updateResolvConf = true;
      };

      # Create auth file with username and password before OpenVPN starts
      systemd.services.openvpn-protonvpn = {
        preStart = ''
          mkdir -p /run/openvpn
          mkdir -p /tmp/openvpn
          echo "$(cat ${usernameFile})" > /run/openvpn/protonvpn.auth
          echo "$(cat ${passwordFile})" >> /run/openvpn/protonvpn.auth
          chmod 600 /run/openvpn/protonvpn.auth
        '';
      };

      # Kill switch implementation
      networking.firewall.extraCommands = lib.mkIf killswitch.enable ''
        # VPN Kill Switch: Block all OUTPUT except VPN, loopback, and allowed traffic

        # Allow loopback
        iptables -A nixos-fw -o lo -j ACCEPT

        # Allow VPN interface (${dev})
        iptables -A nixos-fw -o ${dev} -j ACCEPT

        # Allow established connections
        iptables -A nixos-fw -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

        # Allow traffic to allowed subnets
        ${lib.concatMapStrings (subnet: ''
            iptables -A nixos-fw -d ${subnet} -j ACCEPT
          '')
          killswitch.allowedSubnets}

        # Allow exempt ports
        ${lib.concatMapStrings (port: ''
            iptables -A nixos-fw -p tcp --dport ${toString port} -j ACCEPT
            iptables -A nixos-fw -p udp --dport ${toString port} -j ACCEPT
          '')
          killswitch.exemptPorts}

        # Block everything else
        iptables -A nixos-fw -j DROP
      '';

      # Required packages
      environment.systemPackages = with pkgs; [
        openvpn
        cifs-utils # For SMB if needed
      ];

      # OpenVPN needs permissions to read the password file
      systemd.services.openvpn-protonvpn.serviceConfig.SupplementaryGroups = ["keys"];
    };
  };
}
