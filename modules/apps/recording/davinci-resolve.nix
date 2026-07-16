# DaVinci Resolve — video editing, color, and A/V post production
# Parametric: pass { studio = true; } for the paid Studio edition (h.264/h.265/AAC),
# omit or { studio = false; } for the free edition.
# Usage: (fleet.apps._.davinci-resolve { studio = true; })
#
# Resolve 21: our nixpkgs still ships 20.x, so packages/davinci-resolve/package.nix
# is vendored from nixpkgs PR #527765 (davinci-resolve: 20.3.3 -> 21.0) with the
# Studio source hash corrected — Blackmagic re-uploaded the 21.0 zip after the PR
# was opened, so the PR's hash no longer matches. Once 21.x lands in our pinned
# nixpkgs, delete the vendored package and go back to pkgs.davinci-resolve(-studio).
{
  fleet,
  ...
}:
{
  fleet.apps._.davinci-resolve.description = "DaVinci Resolve video editor (free or Studio)";

  fleet.apps._.davinci-resolve.__functor =
    _self:
    {
      studio ? false,
      ...
    }:
    {
      nixos =
        { pkgs, ... }:
        {
          environment.systemPackages = [
            (pkgs.callPackage ../../../packages/davinci-resolve/package.nix {
              studioVariant = studio;
            })
          ];
        };
    };
}
