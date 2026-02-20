# Default aspect configuration
# see also: aspects/developer.nix, aspects/example/
{
  den,
  __findFile,
  FTS,
  pkgs,
  ...
}:
{
  # see also defaults.nix where static settings are set.
  den.default = {
    # parametric defaults for host/user/home. see aspects/dependencies.nix
    # `_` is shorthand alias for `provides`.
    includes = [
      <den/home-manager> # den.provides.home-manager
      <den/define-user> # Built-in user + home wiring
      <FTS/hostname> # Hostname configuration
      <FTS/state-version> # Centralized state versions
      FTS.coding._.cli
    ];
    host.includes = [
      <FTS/nh>
      # System aspects
      <FTS/system> # Essential system utilities
      <FTS/fonts>
      <FTS/phoenix>
      <FTS/experimental-features> # Enable nix-command and flakes
      # <FTS/secrets>  # SOPS secrets management - disabled, using SelfHostBlocks SOPS instead
      # Allow unfree packages
      (<den/unfree> true)
      # Boot loader - disabled by default, enable per-host as needed
      # (<FTS/grub> { })
      # Nix configuration (includes nixpkgs overlays, unfree-default, etc.)
      <FTS/nix>
    ];

    user.includes = [
      # User-specific modules can be added here
    ];
    home.includes = [
      # Nix tools (nix-index, nix-registry, npins, search are included via FTS.nix)
      <FTS/nix>
      # Also include search directly to test
      # <FTS/secrets>  # SOPS secrets infrastructure (home-manager part) - disabled, using SelfHostBlocks SOPS instead
      <FTS/user-secrets> # User secrets from SOPS with environment variables
    ];
  };
}
