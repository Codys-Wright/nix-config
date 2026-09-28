# Tailscale module - Secure mesh VPN
{
  fleet,
  ...
}:
{
  fleet.networking._.tailscale = {
    description = "Tailscale VPN service";

    nixos =
      {
        config,
        pkgs,
        ...
      }:
      {
        services.tailscale = {
          enable = true;
          useRoutingFeatures = "client";
        };

        networking.firewall.allowedUDPPorts = [ config.services.tailscale.port ];
      };

  };
}
