{ inputs, lib, ... }:
{
  # Floe's own nix/package.nix pins zig-overlay's 0.14.0 exactly (not
  # nixpkgs' zig_0_14, currently 0.14.1) — its build.zig.zon.nix dependency
  # hashes were repacked against that specific build, so match it here.
  flake-file.inputs.zig-overlay.url = lib.mkDefault "github:mitchellh/zig-overlay";

  perSystem =
    { pkgs, system, ... }:
    lib.optionalAttrs (system == "x86_64-linux") {
      packages.floe = pkgs.callPackage ../../packages/floe/floe.nix {
        zig_0_14 = inputs.zig-overlay.packages.${system}."0.14.0";
      };
    };
}
