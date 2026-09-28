{ ... }:
{
  flake-file.inputs.nixos-wsl = {
    url = "github:nix-community/nixos-wsl";
    # Fleet aspects target the main (unstable) nixpkgs; NixOS-WSL follows it.
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.flake-compat.follows = "";
  };

  # Consumed by den's wsl battery (den.hosts.<sys>.<host>.wsl.enable).
}
