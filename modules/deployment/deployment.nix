# Deployment facet - All deployment and bootstrap tools
# Parametric aspect that accepts deployment configuration
{ fleet, ... }:
{
  fleet.deployment.description = ''
    Deployment and system bootstrap facet.

    Implements skarabox-like functionality for bootstrapping and managing
    NixOS systems remotely. Fully integrated with fleet modules like custom
    storage (mergerfs), disk configurations, and hardware detection.

    Features:
    - nixos-anywhere for headless installation
    - disko for declarative disk partitioning
    - nixos-facter for hardware detection
    - sops-nix for secrets management
    - Remote SSH access during boot (for encrypted disk unlocking)
    - WiFi hotspot for bootstrap scenarios

    Usage (parametric - recommended):
      (<fleet.deployment> { ip = "192.168.1.100"; })        # With deploy-rs IP
      (<fleet.deployment> { ip = "192.168.1.100"; sshPort = 2222; })
      (<fleet.deployment> {})                               # With defaults (no deploy-rs)

    See modules/deployment/USAGE.md for detailed documentation.
  '';

  # Make deployment callable as a parametric aspect
  fleet.deployment.__functor =
    _self:
    {
      # Deploy-rs parameters (passed to config)
      ip ? "",
      sshPort ? 22,
      sshUser ? "admin",
      # Network configuration
      staticNetwork ? null,
      # User configuration
      username ? "admin",
      ...
    }@args:
    {
      class,
      aspect-chain,
    }:
    {
      includes = [
        # Base deployment configuration with parameters
        (fleet.deployment._.config args)
        # Boot SSH for remote unlocking (auto-detects host keys)
        (fleet.deployment._.bootssh { })
        # WiFi hotspot (disabled by default, set deployment.hotspot.enable = true)
        fleet.deployment._.hotspot
        fleet.deployment._.wifi
        fleet.deployment._.tor-ssh
        fleet.deployment._.restore-remote-access
        # Beacon is for creating installation ISOs - include it separately when needed:
        # (<fleet.deployment/beacon> {})  # Uses deployment.config defaults
        # Note: VM and ISO generation are defined in den.provides (modules/deployment/vm.nix and iso.nix)
        # They're perSystem modules that generate packages, included via den.default
      ];
    };
}
