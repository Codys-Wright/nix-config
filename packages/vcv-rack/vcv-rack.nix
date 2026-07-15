{ pkgs }:

# nixpkgs' vcv-rack fetches its Linux segfault-fix patch from
# https://github.com/VCVRack/Rack/pull/1944.patch, but that PR no longer
# exists (404) so the build fails before it even starts. Upstream nixpkgs
# fixed this by vendoring the patch from its underlying commit instead of
# fetching the (now-gone) PR diff; do the same here until the flake's
# nixpkgs pin picks up that fix.
pkgs.vcv-rack.overrideAttrs (old: {
  patches = [
    (builtins.elemAt old.patches 0)
    ./fix-segfault-on-linux.patch
  ];
})
