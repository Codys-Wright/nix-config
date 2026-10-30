{ callPackage }:

callPackage ../_craft/mk-craft-app.nix { } {
  pname = "designcraft";
  version = "0.14.0";
  hash = "sha256-eQrDZN4ADUjXXAndAc1QNZ+LNGV0TLRJ4CopmzAwfBM=";
  cargoHash = "sha256-4TXmagOH4NbYSwHQ/M/8pjGQTWOoLDxuFA0yTPGtoDI=";
  releaseDate = "2026-10-28";
  description = "Page layout and publishing, a free alternative to InDesign";
}
