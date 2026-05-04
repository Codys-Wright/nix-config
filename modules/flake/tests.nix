# CI checks to ensure flake outputs evaluate cleanly
# Run with: nix flake check
{ ... }:
{
  perSystem =
    {
      pkgs,
      self',
      ...
    }:
    let
      checkCond = name: cond: pkgs.runCommandLocal name { } (if cond then "touch $out" else "");

      # Check that ISO packages are available (if iso.nix is included)
      isoPackageChecks =
        if self' ? packages && self'.packages ? dave then
          {
            "iso-dave-package" = checkCond "iso-dave-package" (builtins.pathExists self'.packages.dave);
          }
        else
          { };
    in
    {
      checks = {
        flake-module-evaluates = checkCond "flake-module-evaluates" true;
      }
      // isoPackageChecks;
    };
}
