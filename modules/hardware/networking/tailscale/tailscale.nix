# Tailscale module - Secure mesh VPN
{
  FTS,
  ...
}:
{
  FTS.hardware._.networking._.tailscale = {
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

        networking.firewall.allowedUDPPorts = config.services.tailscale.port;
      };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.tailscale ];
      };
  };
}
