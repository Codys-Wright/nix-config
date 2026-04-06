# Disable man cache generation for faster rebuilds
# man <command> still works, only apropos/man -k is affected
{ fleet, ... }:
{
  fleet.no-man-cache = {
    description = "Disable slow man cache generation for faster system rebuilds";

    # NixOS system-level
    nixos =
      { ... }:
      {
        documentation.man.cache.enable = false;
      };

    # Darwin system-level (if applicable)
    darwin =
      { ... }:
      {
        # nix-darwin doesn't have this option at system level
      };

    # Home-manager level (where fish triggers the cache)
    homeManager =
      { ... }:
      {
        programs.man.generateCaches = false;
      };
  };
}
