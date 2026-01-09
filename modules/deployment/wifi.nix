# WiFi module for beacon installation environment
# Uses iwd (iNet Wireless Daemon) for better CLI experience
{
  FTS,
  lib,
  ...
}:
{
  FTS.deployment._.wifi = {
    description = ''
      WiFi support for beacon installation environment using iwd.

      iwd provides a user-friendly CLI for connecting to wireless networks:
        iwctl device list
        iwctl station wlan0 scan
        iwctl station wlan0 get-networks
        iwctl station wlan0 connect "SSID"

      Usage:
        FTS.deployment._.wifi  # Include in beacon aspect
    '';

    # Include networkd aspect for base networking
    includes = [ FTS.deployment._.networkd ];

    nixos =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        # Disable wpa_supplicant in favor of iwd
        networking.wireless.enable = lib.mkForce false;

        # Use iwd instead of wpa_supplicant
        networking.wireless.iwd = {
          enable = true;
          settings = {
            Network = {
              EnableIPv6 = true;
              RoutePriorityOffset = 300;
            };
            Settings.AutoConnect = true;
          };
        };

        # Add helpful wifi utilities
        environment.systemPackages = with pkgs; [
          iw
          wirelesstools
        ];
      };
  };
}
