# RaySession audio sub-aspect (can be included independently)
{
  fleet,
  lib,
  ...
}:
let
  raysessionHelpers = import ./_lib.nix { inherit lib; };
in
{
  fleet.audio._.raysession = {
    description = "RaySession audio session manager";

    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          (raysessionHelpers.mkRaysessionPackage pkgs)
        ];
      };
  };
}
