# Communications aggregator
{ fleet, ... }:
{
  fleet.apps._.communications = {
    description = "Communication apps - Discord, Telegram";
    includes = [
      fleet.apps._.communications._.discord
      fleet.apps._.communications._.telegram
      fleet.apps._.communications._.protonmail-bridge
    ];
  };
}
