# Icon theme configuration aspect
# Configures icon theming for the desktop
{
  FTS,
  lib,
  ...
}:
{
  FTS.theme._.icons.description = "Icon theme configuration";

  # Function that produces an icon theme aspect
  # Usage: (FTS.theme._.icons { theme = "whitesur"; })
  FTS.theme._.icons.__functor =
    _self:
    {
      theme ? null,
      ...
    }@args:
    { class, aspect-chain }:
    let
      # Available icon themes (from theme providers)
      availableThemes = ["whitesur" "whitesur-dark"];
      
      # Validate theme if provided
      _ = if theme != null && !(builtins.elem theme availableThemes)
        then throw "icons: unknown theme '${theme}'. Available: ${builtins.concatStringsSep ", " availableThemes}"
        else null;
      
      # Theme includes
      themeIncludes = if theme == "whitesur" then [ FTS.theme._.icons._.themes._.whitesur ]
        else if theme == "whitesur-dark" then [ FTS.theme._.icons._.themes._.whitesur-dark ]
        else [];
    in
    {
      includes = themeIncludes;
    };
}

