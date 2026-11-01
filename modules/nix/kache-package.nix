# kache from its own flake, pinned to a release tag, as `pkgs.kache` on every
# class (nixos, darwin, home-manager), replacing nixpkgs' kache. Everything
# that installs kache (modules/coding/lang/kache.nix, the hosts' kache.nix)
# keeps saying `pkgs.kache`; this file only picks which kache that is.
#
# kache 2 ships two binaries that must sit in one directory: `kache` (the
# thin client Cargo runs as its rustc wrapper) and `kache-engine` (the CLI,
# daemon and local cache path); the client canonicalizes its own path and
# runs the engine beside it (kache-shims `companion::engine_for`). Upstream's
# package builds the `kache` crate, which has both as [[bin]], so its bin/
# holds the pair.
#
# Built with the toolchain upstream pins (rust-toolchain.toml, through its
# rust-overlay input): kache 2 needs rustc >= 1.95. Its ~2000-test suite is
# skipped here; upstream's CI runs it, and a sandbox-only failure would block
# every host's build.
#
# x86_64-darwin is not in upstream's flake (nixpkgs dropped it), so a host
# there keeps nixpkgs' kache.
{ inputs, lib, ... }:
let
  overlay =
    final: prev:
    let
      upstream = inputs.kache.packages.${prev.stdenv.hostPlatform.system} or null;
    in
    {
      kache =
        if upstream == null then
          prev.kache
        else
          upstream.kache.overrideAttrs {
            doCheck = false;
          };
    };
in
{
  flake-file.inputs.kache.url = lib.mkDefault "github:kunobi-ninja/kache/v2.0.0-rc.3";
  flake-file.inputs.kache.inputs.nixpkgs.follows = "nixpkgs";

  fleet.nix._.kache-package = {
    description = "kache (client + kache-engine) from its upstream flake at a pinned tag, as pkgs.kache";
    nixos.nixpkgs.overlays = [ overlay ];
    darwin.nixpkgs.overlays = [ overlay ];
    homeManager.nixpkgs.overlays = [ overlay ];
  };
}
