# Miscellaneous apps aggregator
{ FTS, ... }:
{
  FTS.apps._.misc = {
    description = "Miscellaneous apps - AppImage, Flameshot, LocalSend, Nextcloud";
    includes = [
      FTS.apps._.misc._.appimage
      FTS.apps._.misc._.flameshot
      FTS.apps._.misc._.localsend
      FTS.apps._.misc._.nextcloud-client
    ];
  };
}
