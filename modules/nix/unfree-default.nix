# Enable unfree packages globally for all classes
# This sets allowUnfree = true for nixos, darwin, and homeManager
{FTS, ...}: {
  FTS.nix._.unfree-default = {
    description = "Enable unfree packages globally for nixos, darwin, and homeManager";
    nixos.nixpkgs.config.allowUnfree = true;
    darwin.nixpkgs.config.allowUnfree = true;
    homeManager.nixpkgs.config.allowUnfree = true;
  };
}
