# Basic networking configuration
{
  FTS,
  ...
}:
{
  FTS.system._.networking = {
    description = "Basic networking with systemd-networkd (DHCP by default)";

    nixos = { config, lib, pkgs, ... }: {
      # Use systemd-networkd for network management
      systemd.network = {
        enable = lib.mkDefault true;
        networks."10-lan" = lib.mkDefault {
          matchConfig.Name = "en*";
          networkConfig.DHCP = "ipv4";
          linkConfig.RequiredForOnline = true;
        };
      };
      
      # Enable resolved for DNS
      services.resolved.enable = lib.mkDefault true;
    };
  };
}

