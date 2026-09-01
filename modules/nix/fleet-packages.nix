# Canonical wiring for the local packages/ tree.
#
# Every packages/<name>/package.nix is auto-discovered and exposed as
# pkgs.<name> via one overlay applied to all three classes, so aspects
# reference `pkgs.<name>` (or `pkgs.<name>.override { ... }`) instead of
# repeating relative `callPackage ../../packages/...` paths. The same
# attrset backs the flake's `packages.<system>.*` outputs below.
#
# Naming rules:
#   - dirs whose name collides with an existing nixpkgs attr are exposed
#     with a `fleet-` prefix so the overlay never shadows nixpkgs (which
#     would silently change module defaults like services.sunshine.package)
#   - multi-package dirs (no package.nix) are wired explicitly with
#     flattened names: mactahoe-<part>, tiagolr-<plugin>
{
  inputs,
  lib,
  fleet,
  ...
}:
let
  packagesDir = ../../packages;
  entries = builtins.readDir packagesDir;
  hasPackageNix =
    n: entries.${n} == "directory" && builtins.pathExists (packagesDir + "/${n}/package.nix");
  autoNames = builtins.filter hasPackageNix (builtins.attrNames entries);

  # nixpkgs already has attrs with these names — prefix to avoid shadowing.
  collides = [
    "davinci-resolve"
    "inferno"
    "melonloader-installer"
  ];
  attrName = n: if builtins.elem n collides then "fleet-${n}" else n;

  # Floe's own nix/package.nix pins zig-overlay's 0.14.0 exactly (not
  # nixpkgs' zig_0_14, currently 0.14.1) — its build.zig.zon.nix dependency
  # hashes were repacked against that specific build, so match it here.
  # Per-system extra callPackage args. Guarded with optionalAttrs so
  # evaluating the attrset on a system an input doesn't support yields a
  # catchable missing-argument throw (from callPackage) instead of an
  # uncatchable missing-attribute error.
  extraArgs =
    final:
    let
      system = final.stdenv.hostPlatform.system;
    in
    {
      floe = lib.optionalAttrs (inputs.zig-overlay.packages ? ${system}) {
        zig_0_14 = inputs.zig-overlay.packages.${system}."0.14.0";
      };
      # Wine app built with erosanix's mkWindowsApp toolkit (flake input).
      axe-edit-iii = lib.optionalAttrs (inputs.erosanix.lib ? ${system}) {
        inherit (inputs.erosanix.lib.${system})
          mkWindowsApp
          makeDesktopIcon
          copyDesktopIcons
          ;
        wine = final.wineWow64Packages.full;
      };
    };

  overlay =
    final: _prev:
    lib.listToAttrs (
      map (n: {
        name = attrName n;
        value = final.callPackage (packagesDir + "/${n}/package.nix") ((extraArgs final).${n} or { });
      }) autoNames
    )
    // {
      mactahoe-gtk-theme = final.callPackage ../../packages/mactahoe/gtk-theme.nix { };
      mactahoe-icon-theme = final.callPackage ../../packages/mactahoe/icon-theme.nix { };
      mactahoe-cursor-theme = final.callPackage ../../packages/mactahoe/cursor-theme.nix { };
      mactahoe-kde-theme = final.callPackage ../../packages/mactahoe/kde-theme.nix { };
      tiagolr-time12 = final.callPackage ../../packages/tiagolr/time12.nix { };
      tiagolr-filtr = final.callPackage ../../packages/tiagolr/filtr.nix { };
      tiagolr-reevr = final.callPackage ../../packages/tiagolr/reevr.nix { };
      tiagolr-gate12 = final.callPackage ../../packages/tiagolr/gate12.nix { };
      tiagolr-ripplerx = final.callPackage ../../packages/tiagolr/ripplerx.nix { };
    };

  fleetAttrNames = map attrName autoNames ++ [
    "mactahoe-gtk-theme"
    "mactahoe-icon-theme"
    "mactahoe-cursor-theme"
    "mactahoe-kde-theme"
    "tiagolr-time12"
    "tiagolr-filtr"
    "tiagolr-reevr"
    "tiagolr-gate12"
    "tiagolr-ripplerx"
  ];
in
{
  flake-file.inputs.zig-overlay.url = lib.mkDefault "github:mitchellh/zig-overlay";

  fleet.nix._.fleet-packages = {
    description = "Overlay exposing every local packages/ derivation as pkgs.<name>";
    nixos.nixpkgs.overlays = [ overlay ];
    darwin.nixpkgs.overlays = [ overlay ];
    homeManager.nixpkgs.overlays = [ overlay ];
  };

  # Flake `packages.*` outputs derived from the same overlay. Exposed on
  # x86_64-linux only (the old per-package shims' behavior): forcing these
  # derivations on darwin aborts inside callPackage for the linux-only
  # packages, and nothing consumes the outputs there.
  perSystem =
    { pkgs, system, ... }:
    {
      packages = lib.optionalAttrs (system == "x86_64-linux") (
        lib.getAttrs fleetAttrNames (pkgs.extend overlay)
      );
    };
}
