# Browsers facet - All web browsers
{FTS, ...}: {
  FTS.apps._.misc = {
    description = "misc apps";

    includes = [
      # FTS.apps._.misc._.nextcloud-client  # Not available on aarch64-darwin
      FTS.apps._.misc._.localsend
      FTS.apps._.misc._.flameshot
      FTS.apps._.misc._.appimage
    ];
  };
}
