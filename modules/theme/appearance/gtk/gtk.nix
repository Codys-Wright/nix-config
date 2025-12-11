# GTK theme configuration aspect
# Configures GTK theming for applications
{
  FTS,
  lib,
  ...
}:
{
  FTS.theme._.gtk.description = "GTK theme configuration";

  # Function that produces a GTK theme aspect
  # Usage: (FTS.theme._.gtk { theme = "WhiteSur-Dark"; })
  FTS.theme._.gtk.__functor =
    _self:
    {
      theme ? null,
      ...
    }@args:
    { class, aspect-chain }:
    let
      # Available GTK themes (from theme providers)
      availableThemes = ["whitesur" "whitesur-light"];
      
      # Validate theme if provided
      _ = if theme != null && !(builtins.elem theme availableThemes)
        then throw "gtk: unknown theme '${theme}'. Available: ${builtins.concatStringsSep ", " availableThemes}"
        else null;
      
      # Theme includes
      themeIncludes = if theme == "whitesur" then [ FTS.theme._.gtk._.themes._.whitesur ]
        else if theme == "whitesur-light" then [ FTS.theme._.gtk._.themes._.whitesur-light ]
        else [];
    in
    {
      includes = themeIncludes;
    };
}

