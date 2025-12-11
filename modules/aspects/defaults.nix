# Default aspect configuration
# see also: aspects/developer.nix, aspects/example/
{
  inputs,
  den,
  lib,
  __findFile,
  ...
}:
{
  # see also defaults.nix where static settings are set.
  den.default = {
    # parametric defaults for host/user/home. see aspects/dependencies.nix
    # `_` is shorthand alias for `provides`.
    includes = [
      <den/home-manager>  # den.provides.home-manager
      den.aspects.hm-backup
      den.aspects.example._.routes
      den.aspects.example._.user
      den.aspects.example._.host
      den.aspects.example._.home
      <den/vm>   # den.provides.vm
      <den/iso>  # den.provides.iso
    ];
    host.includes = [
      <FTS/nh>
      # System aspects
      <FTS/fonts>
      <FTS/phoenix>
      <FTS/experimental-features>  # Enable nix-command and flakes
      <FTS/secrets>  # SOPS secrets management
      # Allow unfree packages
      (<den/unfree> true)
      # Boot loader - disabled by default, enable per-host as needed
      # (<FTS/grub> { })
    ];
    user.includes = [ <FTS/example/user> ];
    home.includes = [
      <FTS/example/home>
      den.aspects.nix-index
      den.aspects.nix-registry
      <FTS/secrets>  # SOPS secrets infrastructure (home-manager part)
      <FTS/user-secrets>  # User secrets from SOPS with environment variables
    ];
  };
}

