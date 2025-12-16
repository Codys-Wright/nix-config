# Theme facet - Router for theme presets
# Applies coordinated theming across desktop, bootloader, display manager, etc.
{
  FTS,
  lib,
  ...
}:
{
  FTS.theme.description = ''
    Theme configuration facet - Context-aware theming for system and user levels.

    System-level usage (in host aspect):
      (<FTS/theme> { default = "cody"; })
      # Applies: bootloader theme, system defaults, user defaults

    User-level usage (in user aspect):
      (<FTS/theme> { default = "whitesur"; })
      # Applies: user appearance only (GTK, Qt, icons, cursors, fonts)
      # System theme (bootloader) remains unchanged

    Direct access to presets:
      (<FTS/theme/presets/minecraft> { })
      (<FTS/theme/presets/whitesur> { })
      (<FTS/theme/presets/cody> { })

    How it works:
    - Automatically detects if used in user vs system context
    - System context: Everything applies
    - User context: Only homeManager configs apply, system uses mkDefault
    - This means users can have different themes while sharing bootloader

    Benefits:
    - Single interface for both system and user themes
    - Context-aware - knows where it's being used
    - Type-safe - same validated presets everywhere
    - Clean - no separate user-theme module needed
  '';

  # Make theme callable as a router
  FTS.theme.__functor =
    _self:
    {
      default ? null,
      ...
    }@args:
    {
      class,
      aspect-chain,
      user ? null,
      host ? null,
      ...
    }:
    let
      # Available theme presets
      availableThemes = [
        "minecraft"
        "whitesur"
        "cody"
      ]; # Will add more: catppuccin, nord, dracula, etc.

      # Validate theme
      _ =
        if default != null && !(builtins.elem default availableThemes) then
          throw "theme: unknown theme '${default}'. Available: ${builtins.concatStringsSep ", " availableThemes}"
        else
          null;

      # Detect context: user-level or system-level
      isUserContext = user != null;

      # Build includes - just include the preset, which itself includes FTS aspects
      themeIncludes = lib.optionals (default != null) [
        FTS.theme._.presets._.${default}
      ];
    in
    {
      includes = themeIncludes;

      # Context info for debugging
      # ${if isUserContext then "User-level theme for ${user.userName}" else "System-level theme"}
    };
}
