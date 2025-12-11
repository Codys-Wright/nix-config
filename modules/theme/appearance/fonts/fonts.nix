# Font configuration aspect
# Configures system and user fonts
{
  FTS,
  lib,
  ...
}:
{
  FTS.theme._.fonts.description = "Font configuration";

  # Function that produces a font configuration aspect
  # Usage: (FTS.theme._.fonts { preset = "modern"; })
  FTS.theme._.fonts.__functor =
    _self:
    {
      preset ? null,
      ...
    }@args:
    { class, aspect-chain }:
    let
      # Available font presets
      availablePresets = ["modern" "programming" "macos"];
      
      # Validate preset if provided
      _ = if preset != null && !(builtins.elem preset availablePresets)
        then throw "fonts: unknown preset '${preset}'. Available: ${builtins.concatStringsSep ", " availablePresets}"
        else null;
      
      # Preset includes
      presetIncludes = if preset == "modern" then [ FTS.theme._.fonts._.presets._.modern ]
        else if preset == "programming" then [ FTS.theme._.fonts._.presets._.programming ]
        else if preset == "macos" then [ FTS.theme._.fonts._.presets._.macos ]
        else [];
    in
    {
      includes = presetIncludes;
    };
}

