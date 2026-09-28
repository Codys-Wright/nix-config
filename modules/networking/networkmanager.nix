# Networking hardware aspect — use NetworkManager instead of systemd-networkd
{ fleet, ... }:
{
  fleet.networking._.networkmanager = {
    description = "NetworkManager networking (physical machines; <fleet/networking> then skips networkd)";

    nixos =
      { lib, ... }:
      {
        networking.networkmanager.enable = true;

        # Enable network manager applet
        programs.nm-applet.enable = true;

        # Disable systemd network wait-online (NM handles this)
        systemd.network.wait-online.enable = false;
      };
  };
}
