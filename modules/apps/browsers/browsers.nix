# Browser aggregator
{ FTS, ... }:
{
  FTS.apps._.browsers = {
    description = "Web browsers - Zen, Brave, Firefox";
    includes = [
      FTS.apps._.browsers._.zen
      FTS.apps._.browsers._.brave
      FTS.apps._.browsers._.firefox
    ];
  };
}
