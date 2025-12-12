# Deployment facet - All deployment and bootstrap tools
{
  FTS,
  ...
}:
{
  FTS.deployment = {
    description = ''
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
      
      See modules/deployment/USAGE.md for detailed documentation.
    '';

    includes = [
      FTS.deployment._.config      # Base deployment configuration (SSH, networking, user setup)
      (FTS.deployment._.bootssh {})  # Boot SSH for remote unlocking (auto-detects host keys)
      FTS.deployment._.hotspot     # WiFi hotspot (disabled by default, set deployment.hotspot.enable = true)
      FTS.deployment._.secrets     # Secrets management (auto-enabled if secrets.yaml exists)
      # Beacon is for creating installation ISOs - include it separately when needed:
      # (<FTS.deployment/beacon> {})  # Uses deployment.config defaults
      # Note: VM and ISO generation are defined in den.provides (modules/deployment/vm.nix and iso.nix)
      # They're perSystem modules that generate packages, included via den.default
    ];
  };
}

