# Browser aggregator
{ fleet, ... }:
{
  fleet.apps._.browsers = {
    description = "Web browsers - Zen, Brave, Firefox";
    includes = [
      fleet.apps._.browsers._.zen
      fleet.apps._.browsers._.brave
      fleet.apps._.browsers._.firefox
    ];
  };
}
