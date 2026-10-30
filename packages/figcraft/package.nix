{ callPackage }:

callPackage ../_craft/mk-craft-app.nix { } {
  pname = "figcraft";
  version = "0.12.1";
  hash = "sha256-rdnFZGi7YeGtcfpRgY8ICp0sXOKNqX1vCwBAvZxXKxo=";
  cargoHash = "sha256-aFD3NwF6+y6sG1OlZIhE0G6I7iNNxwgWihC760/eKCs=";
  releaseDate = "2026-10-28";
  description = "Interface design and prototyping, a free alternative to Figma";
}
