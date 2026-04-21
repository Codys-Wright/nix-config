# RaySession audio sub-aspect (can be included independently)
{
  fleet,
  lib,
  ...
}:
let
  raysessionHelpers = import ../../../../lib/audio/raysession/common.nix { inherit lib; };
in
{
  fleet.raysession = {
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
