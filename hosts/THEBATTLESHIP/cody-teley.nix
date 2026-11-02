# cody's always-on Teley on THEBATTLESHIP (STA-642): the worker on :8787 and
# the OTLP collector on :4318, as home-manager user services.
{ fleet, ... }:
{
  den.aspects."cody@THEBATTLESHIP".includes = [ fleet.coding._.cli._.teley ];
}
