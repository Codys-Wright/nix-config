# Enable unfree packages globally for all classes
# This sets allowUnfree = true for nixos, darwin, and homeManager
{ fleet, ... }:
{
  fleet.nix._.unfree-default = {
    description = "Enable unfree packages globally for nixos, darwin, and homeManager";
    nixos.nixpkgs.config.allowUnfree = true;
    nixos.nixpkgs.config.android_sdk.accept_license = true;
    darwin.nixpkgs.config.allowUnfree = true;
    homeManager.nixpkgs.config.allowUnfree = true;
    homeManager.nixpkgs.config.android_sdk.accept_license = true;
  };
}
