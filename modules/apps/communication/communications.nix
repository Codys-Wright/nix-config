# Communications aggregator
{ FTS, ... }:
{
  FTS.apps._.communications = {
    description = "Communication apps - Discord, Telegram";
    includes = [
      FTS.apps._.communications._.discord
      FTS.apps._.communications._.telegram
    ];
  };
}
