{
  fleet.apps._.misc._.unshuffle = {
    description = "unshuffle - producer-first sample-library staging and migration tool";

    homeManager =
      { pkgs, lib, ... }:
      {
        home.packages = lib.optionals pkgs.stdenv.isLinux [
          (pkgs.callPackage ../../../packages/unshuffle/unshuffle.nix { })
        ];
      };
  };
}
