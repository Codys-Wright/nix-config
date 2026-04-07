# Printing support via CUPS
{ fleet, ... }:
{
  fleet.system._.printing = {
    description = "CUPS printing with network printer auto-discovery";

    nixos =
      { pkgs, ... }:
      {
        services.printing = {
          enable = true;
          drivers = with pkgs; [
            gutenprint
            hplip
          ];
        };

        # Avahi for network printer discovery (mDNS)
        services.avahi = {
          enable = true;
          nssmdns4 = true;
        };
      };
  };
}
