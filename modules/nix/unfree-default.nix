# Enable unfree packages globally for all classes
# This sets allowUnfree = true for nixos, darwin, and homeManager
{FTS, ...}: {
  # Unfree default aspect - enables unfree packages globally
  FTS.nix._.unfree-default = {
    description = "Enable unfree packages globally for nixos, darwin, and homeManager";
    # This aspect configures flake-level nixpkgs config, so it applies to all classes
  };

  # Enable unfree packages for darwin/nixos/home-manager modules
  flake.modules.darwin.nixpkgs.config.allowUnfree = true;
  flake.modules.nixos.nixpkgs.config.allowUnfree = true;
  flake.modules.homeManager.nixpkgs.config.allowUnfree = true;
}
