# Default aspect configuration
# see also: aspects/developer.nix, aspects/example.nix
{
  inputs,
  den,
  lib,
  ...
}:
{
  # see also defaults.nix where static settings are set.
  den.default = {
    # parametric defaults for host/user/home. see aspects/dependencies.nix
    # `_` is shorthand alias for `provides`.
    host.includes = [
      den.aspects.example._.host
      den.aspects.nh
      # System aspects
      den.aspects.fonts
      den.aspects.phoenix
      # Boot loader - disabled by default, enable per-host as needed
      # den.aspects.grub
    ];
    user.includes = [ den.aspects.example._.user ];
    home.includes = [
      den.aspects.example._.home
      # Include coding aspects for all homes
      den.aspects.cli-tools
      den.aspects.shell-tools
      # Include language support
      den.aspects.rust
      den.aspects.typescript
      # Include development tools
      den.aspects.git
      den.aspects.docker
      den.aspects.lazygit
      den.aspects.opencode
      den.aspects.dev-tools
      # Include desktop environment (for Linux systems)
      den.aspects.desktop-keybinds
      # Enable Hyprland desktop environment
      den.aspects.hyprland-keybinds
    ];
  };
}

