# Avahi - mDNS/DNS-SD service discovery
# Enables .local hostname resolution and service publishing
{
  fleet,
  ...
}:
{
  fleet.system._.avahi = {
    description = "Avahi mDNS/DNS-SD for local network service discovery";

    nixos = {
      services.avahi = {
        enable = true;
        nssmdns4 = true;
        publish = {
          enable = true;
          userServices = true;
        };
      };
    };
  };
}
