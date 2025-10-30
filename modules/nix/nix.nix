{ ... }:
{
  flake-file.inputs.nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

  # Enable unfree packages for darwin/nixos/home-manager modules
  flake.modules.darwin.nixpkgs.config.allowUnfree = true;
  flake.modules.nixos.nixpkgs.config.allowUnfree = true;
  flake.modules.homeManager.nixpkgs.config.allowUnfree = true;
}
