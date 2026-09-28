# Networking. One tree for the whole stack:
#
#   <fleet/networking>                    default for every host (via <fleet/system>):
#                                         systemd-networkd + DHCP, unless the host
#                                         has NetworkManager
#   <fleet.networking/networkmanager>     physical machines (via <fleet/hardware>)
#   <fleet.networking/tailscale>          mesh VPN
#   (fleet.networking._.network-10g { … }) 10G link to starcommand
#
# networkd vs NetworkManager is decided structurally: a policy guard reads the
# host's resolved tree (den structural introspection), so no mkForce fight.
{ den, fleet, ... }:
{
  fleet.networking = {
    description = "Host networking: systemd-resolved; systemd-networkd unless NetworkManager is present";

    # DNS via resolved on every host, whichever network manager runs.
    nixos =
      { lib, ... }:
      {
        services.resolved.enable = lib.mkDefault true;
      };

    includes = [
      (den.lib.policy.when (
        # host is absent in standalone-home scopes (base-host rides den.default).
        {
          host ? null,
          ...
        }:
        host != null && !(host.hasAspect fleet.networking._.networkmanager)
      ) { includes = [ fleet.networking._.networkd ]; })
    ];
  };
}
