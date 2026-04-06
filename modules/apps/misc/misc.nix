# Miscellaneous apps aggregator
{ fleet, ... }:
{
  fleet.apps._.misc = {
    description = "Miscellaneous apps - AppImage, Flameshot, LocalSend, Nextcloud";
    includes = [
      fleet.apps._.misc._.appimage
      fleet.apps._.misc._.flameshot
      fleet.apps._.misc._.localsend
      fleet.apps._.misc._.nextcloud-client
    ];
  };
}
