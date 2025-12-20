# Browsers facet - All web browsers
{FTS, ...}: {
  FTS.apps._.communications = {
    description = "All web communications - brave, firefox";

    includes = [
      FTS.apps._.communications._.discord
      # FTS.apps._.browsers._.zen  # Disabled for now - has module conflicts
    ];
  };
}
