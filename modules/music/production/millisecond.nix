# Millisecond — GTK4 low-latency audio tuning diagnostics (rtcqs-based)
{ fleet, ... }:
{
  fleet.music._.production._.millisecond = {
    description = "Millisecond low-latency audio tuning diagnostics";

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [ pkgs.millisecond ];
      };
  };
}
