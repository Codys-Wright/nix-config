# Add deployment-related flake inputs
{ inputs, lib, ... }:
{
  # Core deployment tools
  flake-file.inputs.nixos-anywhere.url = lib.mkDefault "github:nix-community/nixos-anywhere";
  flake-file.inputs.nixos-anywhere.inputs.nixpkgs.follows = "nixpkgs";
  
  # Deployment tools (both available, user can choose)
  flake-file.inputs.deploy-rs.url = lib.mkDefault "github:serokell/deploy-rs";
  flake-file.inputs.deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
  
  flake-file.inputs.colmena.url = lib.mkDefault "github:zhaofengli/colmena";
  flake-file.inputs.colmena.inputs.nixpkgs.follows = "nixpkgs";
  
  # Hardware detection
  flake-file.inputs.nixos-facter-modules.url = lib.mkDefault "github:numtide/nixos-facter-modules";
  
  # Secrets management
  flake-file.inputs.sops-nix.url = lib.mkDefault "github:Mic92/sops-nix";
  flake-file.inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";
}

