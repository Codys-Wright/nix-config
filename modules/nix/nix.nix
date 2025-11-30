{ ... }:
{
  flake-file.inputs.nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

  # Enable unfree packages for darwin/nixos/home-manager modules
  flake.modules.darwin.nixpkgs.config.allowUnfree = true;
  flake.modules.nixos.nixpkgs.config.allowUnfree = true;
  flake.modules.homeManager.nixpkgs.config.allowUnfree = true;

  # Enable nix-command and flakes experimental features
  flake.modules.nixos.nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  flake.modules.darwin.nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
