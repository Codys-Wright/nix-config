# Networking hardware aspect — use NetworkManager instead of systemd-networkd
{ fleet, ... }:
{
  fleet.hardware._.networking = {
    description = "NetworkManager networking support (overrides systemd-networkd)";

    nixos =
      { lib, ... }:
      {
        networking.networkmanager.enable = true;

        # Disable systemd-networkd so it doesn't conflict with NetworkManager
        systemd.network.enable = lib.mkForce false;

        # Enable network manager applet
        programs.nm-applet.enable = true;

        # Disable systemd network wait-online (NM handles this)
        systemd.network.wait-online.enable = false;
      };
  };
}
