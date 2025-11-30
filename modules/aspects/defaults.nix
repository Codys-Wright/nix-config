# Default aspect configuration
# see also: aspects/developer.nix, aspects/example/
{
  inputs,
  den,
  lib,
  FTS,
  ...
}:
{
  # see also defaults.nix where static settings are set.
  den.default = {
    # parametric defaults for host/user/home. see aspects/dependencies.nix
    # `_` is shorthand alias for `provides`.
    includes = [
      den._.home-manager
      den.aspects.hm-backup
      den.aspects.example._.routes
      den.aspects.example._.user
      den.aspects.example._.host
      den.aspects.example._.home
      den._.vm  # Enable VM bootable support
      den._.iso  # Enable ISO image generation
    ];
    host.includes = [
      FTS.nh
      # System aspects
      FTS.fonts
      FTS.phoenix
      # Boot loader - disabled by default, enable per-host as needed
      # FTS.grub
    ];
    user.includes = [ FTS.example._.user ];
    home.includes = [
      FTS.example._.home
      den.aspects.nix-index
      den.aspects.nix-registry
    ];
  };
}

