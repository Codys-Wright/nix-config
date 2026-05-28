# DaVinci Resolve — video editing, color, and A/V post production
# Parametric: pass { studio = true; } for the paid Studio edition (h.264/h.265/AAC),
# omit or { studio = false; } for the free edition.
# Usage: (fleet.apps._.davinci-resolve { studio = true; })
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
    { class, aspect-chain }:
    {
      nixos =
        { pkgs, ... }:
        {
          environment.systemPackages = [
            (if studio then pkgs.davinci-resolve-studio else pkgs.davinci-resolve)
          ];
        };
    };
}
