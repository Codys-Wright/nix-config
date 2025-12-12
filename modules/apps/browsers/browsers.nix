# Browsers facet - All web browsers
{
  FTS,
  ...
}:
{
  FTS.apps._.browsers = {
    description = "All web browsers - brave, firefox";
    
    includes = [
      FTS.apps._.browsers._.brave
      FTS.apps._.browsers._.firefox
      # FTS.apps._.browsers._.zen  # Disabled for now - has module conflicts
    ];
  };
}

