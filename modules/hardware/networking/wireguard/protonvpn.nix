# ProtonVPN WireGuard client with kill switch
{
  FTS,
  lib,
  ...
}:
{
  FTS.hardware._.networking._.wireguard._.protonvpn = {
    description = "ProtonVPN WireGuard client with kill switch";

    nixos =
      {
        config,
        pkgs,
        ...
      }:
      {
        networking.wireguard.enable = true;

        networking.wireguard.interfaces.protonvpn = {
          privateKeyFile = "/run/secrets/cody/proton/privatekey";

          ips = [
            "10.2.0.2/32"
            "2a07:b944::2:2/128"
          ];

          peers = [
            {
              publicKey = "1kVqXoxxuSR3WrvykYTRxQD73oQvMtmJfQq7X+HlAQo=";
              allowedIPs = [
                "0.0.0.0/0"
                "::/0"
              ];
              endpoint = "149.40.51.227:51820";
              persistentKeepalive = 25;
            }
          ];
        };

        networking.firewall = {
          enable = lib.mkForce true;
          trustedInterfaces = [ "protonvpn" ];

          allowedUDPPorts = [ 51820 ];

          extraCommands = ''
            # Allow loopback
            iptables -A INPUT -i lo -j ACCEPT
            iptables -A OUTPUT -o lo -j ACCEPT

            # Allow established connections
            iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
            iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

            # Allow WireGuard
            iptables -A INPUT -i protonvpn -j ACCEPT
            iptables -A OUTPUT -o protonvpn -j ACCEPT

            # Allow local network
            iptables -A INPUT -s 192.168.0.0/16 -j ACCEPT
            iptables -A OUTPUT -d 192.168.0.0/16 -j ACCEPT
            iptables -A INPUT -s 10.0.0.0/8 -j ACCEPT
            iptables -A OUTPUT -d 10.0.0.0/8 -j ACCEPT

            # Block all other traffic when VPN is expected to be up
            iptables -A OUTPUT ! -o protonvpn ! -d 192.168.0.0/16 ! -d 10.0.0.0/8 ! -o lo -j REJECT
          '';
        };
      };
  };
}
