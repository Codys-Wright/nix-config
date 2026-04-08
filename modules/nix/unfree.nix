# Standalone unfree aspect — allow all unfree packages across all classes
{ fleet, ... }:
{
  fleet.unfree = {
    description = "Allow all unfree packages globally for nixos, darwin, and homeManager";
    nixos.nixpkgs.config.allowUnfree = true;
    nixos.nixpkgs.config.android_sdk.accept_license = true;
    darwin.nixpkgs.config.allowUnfree = true;
    homeManager.nixpkgs.config.allowUnfree = true;
    homeManager.nixpkgs.config.android_sdk.accept_license = true;
  };
}
