# Facter hardware detection aspect
# Automatically imports nixos-facter-modules for hardware configuration
{
  inputs,
  FTS,
  ...
}:
{
  FTS.hardware._.facter = {
    description = "Hardware detection using nixos-facter";

    nixos = { config, lib, pkgs, ... }:
    let
      # Auto-derive hostname from config (set by den)
      hostname = config.networking.hostName or "nixos";
      
      # Auto-derive facter.json path from hostname
      # Path is relative to flake root: hosts/<hostname>/facter.json
      # We need to construct this as a path relative to the flake root
      # Since we're in a module context, we'll use a path that resolves at evaluation time
      facterConfigPath = ../../hosts/${hostname}/facter.json;
    in
    {
      # Import nixos-facter-modules for hardware detection
      imports = [
        inputs.nixos-facter-modules.nixosModules.facter
      ];

      # Use facter report for hardware detection if it exists
      # Only set if the file exists (allows building before hardware is detected)
      # Path is auto-derived from hostname: hosts/<hostname>/facter.json
      facter.reportPath = lib.mkIf (builtins.pathExists facterConfigPath) facterConfigPath;
      
      # Install nixos-facter package for manual hardware detection
      environment.systemPackages = [ pkgs.nixos-facter ];
    };
  };
}

