# cody's always-on local telemetry on THEBATTLESHIP: OpenObserve on :5080 and
# the OTLP collector on :4318, as home-manager user services (they replace the
# Teley pair of STA-642; Teley is retired on this host).
{ fleet, ... }:
{
  den.aspects."cody@THEBATTLESHIP".includes = [ fleet.coding._.cli._.telemetry ];
}
