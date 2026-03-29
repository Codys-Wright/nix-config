# Flake inputs for niri window manager
{ lib, ... }:
{
  flake-file.inputs.niri-flake.url = lib.mkDefault "github:sodiboo/niri-flake";
  flake-file.inputs.niri-flake.inputs.nixpkgs.follows = "nixpkgs";
}
