# Deployment facet - All deployment and bootstrap tools
# Parametric aspect that accepts deployment configuration
{FTS, ...}: {
  FTS.deployment.description = ''
    Deployment and system bootstrap facet.

    Implements skarabox-like functionality for bootstrapping and managing
    NixOS systems remotely. Fully integrated with FTS modules like custom
    storage (mergerfs), disk configurations, and hardware detection.

    Features:
    - nixos-anywhere for headless installation
    - disko for declarative disk partitioning
    - nixos-facter for hardware detection
    - sops-nix for secrets management
    - Remote SSH access during boot (for encrypted disk unlocking)
    - WiFi hotspot for bootstrap scenarios

    Usage (parametric - recommended):
      (<FTS.deployment> { ip = "192.168.1.100"; })        # With deploy-rs IP
      (<FTS.deployment> { ip = "192.168.1.100"; sshPort = 2222; })
      (<FTS.deployment> {})                               # With defaults (no deploy-rs)

    See modules/deployment/USAGE.md for detailed documentation.
  '';

  # Make deployment callable as a parametric aspect
  FTS.deployment.__functor = _self: {
    # Deploy-rs parameters (passed to config)
    ip ? "",
    sshPort ? 22,
    sshUser ? "admin",
    # Network configuration
    staticNetwork ? null,
    # User configuration
    username ? "admin",
    ...
  } @ args: {
    class,
    aspect-chain,
  }: {
    includes = [
      # Base deployment configuration with parameters
      (FTS.deployment._.config args)
      # Boot SSH for remote unlocking (auto-detects host keys)
      (FTS.deployment._.bootssh {})
      # WiFi hotspot (disabled by default, set deployment.hotspot.enable = true)
      FTS.deployment._.hotspot
      # Beacon is for creating installation ISOs - include it separately when needed:
      # (<FTS.deployment/beacon> {})  # Uses deployment.config defaults
      # Note: VM and ISO generation are defined in den.provides (modules/deployment/vm.nix and iso.nix)
      # They're perSystem modules that generate packages, included via den.default
    ];
  };
}
