# Cursor theme configuration aspect
# Configures cursor theming for the desktop
{
  FTS,
  lib,
  ...
}:
{
  FTS.theme._.cursors.description = "Cursor theme configuration";

  # Function that produces a cursor theme aspect
  # Usage: (FTS.theme._.cursors { theme = "whitesur"; size = 24; })
  FTS.theme._.cursors.__functor =
    _self:
    {
      theme ? null,
      size ? 24,
      ...
    }@args:
    { class, aspect-chain }:
    let
      # Available cursor themes (from theme providers)
      availableThemes = ["whitesur"];
      
      # Validate theme if provided
      _ = if theme != null && !(builtins.elem theme availableThemes)
        then throw "cursors: unknown theme '${theme}'. Available: ${builtins.concatStringsSep ", " availableThemes}"
        else null;
      
      # Theme includes
      themeIncludes = if theme == "whitesur" then [ (FTS.theme._.cursors._.themes._.whitesur { inherit size; }) ]
        else [];
    in
    {
      includes = themeIncludes;
    };
}

