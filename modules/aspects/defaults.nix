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
      den.aspects.dendritic._.routes  # Mutual dependency routing
      den.aspects.dendritic._.user    # User account setup
      den.aspects.dendritic._.host    # Hostname configuration
      den.aspects.dendritic._.home    # Home directory setup
      <den/vm>   # VM generation (perSystem packages)
      <den/iso>  # ISO generation (perSystem packages)
    ];
    host.includes = [
      <FTS/nh>
      # System aspects
      <FTS.system>  # Essential system utilities
      <FTS/fonts>
      <FTS/phoenix>
      <FTS/experimental-features>  # Enable nix-command and flakes
      <FTS/secrets>  # SOPS secrets management
      # Allow unfree packages
      (<den/unfree> true)
      # Boot loader - disabled by default, enable per-host as needed
      # (<FTS/grub> { })
    ];
    user.includes = [ 
      # User-specific modules can be added here
    ];
    home.includes = [
      den.aspects.nix-index
      den.aspects.nix-registry
      <FTS/secrets>  # SOPS secrets infrastructure (home-manager part)
      <FTS/user-secrets>  # User secrets from SOPS with environment variables
    ];
  };
}

