# Qt theme configuration aspect
# Configures Qt theming for applications
{
  FTS,
  lib,
  ...
}:
{
  FTS.theme._.qt.description = "Qt theme configuration";

  # Function that produces a Qt theme aspect
  # Usage: (FTS.theme._.qt { theme = "whitesur"; })
  FTS.theme._.qt.__functor =
    _self:
    {
      theme ? null,
      ...
    }@args:
    { class, aspect-chain }:
    let
      # Available Qt themes (from theme providers)
      availableThemes = ["whitesur"];
      
      # Validate theme if provided
      _ = if theme != null && !(builtins.elem theme availableThemes)
        then throw "qt: unknown theme '${theme}'. Available: ${builtins.concatStringsSep ", " availableThemes}"
        else null;
      
      # Theme includes
      themeIncludes = if theme == "whitesur" then [ FTS.theme._.qt._.themes._.whitesur ]
        else [];
    in
    {
      includes = themeIncludes;
    };
}

