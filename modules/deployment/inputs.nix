# Add deployment-related flake inputs
# These inputs provide the core functionality for deployment and bootstrapping
{ inputs, lib, FTS, ... }:
{
  FTS.deployment._.inputs = {
    description = "Deployment-related flake inputs (informational aspect)";
  };
  
  # Core deployment tools (already in main flake)
  # - nixos-anywhere: Headless NixOS installation
  # - disko: Declarative disk partitioning
  # - nixos-facter-modules: Hardware detection
  # - sops-nix: Secrets management
  # - deploy-rs: Deployment tool
  # - colmena: Alternative deployment tool
  # - nixos-generators: ISO/VM generation
}

