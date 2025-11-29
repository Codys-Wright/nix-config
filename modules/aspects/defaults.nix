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
      # Include coding aspects for all homes
      FTS.cli-tools
      FTS.shell-tools
      # Include language support
      FTS.rust
      FTS.typescript
      # Include development tools
      FTS.git
      FTS.docker
      FTS.lazygit
      FTS.opencode
      FTS.dev-tools
    ];
  };
}

