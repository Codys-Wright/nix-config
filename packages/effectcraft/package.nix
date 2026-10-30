{ callPackage, alsa-lib }:

callPackage ../_craft/mk-craft-app.nix { } {
  pname = "effectcraft";
  version = "0.18.0";
  hash = "sha256-5TDL98KE2j9blT8FeqMOTUznhfdJNOO+exn4LJcth58=";
  cargoHash = "sha256-PxW3amIo5yA2jlupIUePFTx72tdfcmXcyK0/eC79KTM=";
  releaseDate = "2026-10-28";
  description = "Motion graphics and compositing, a free alternative to After Effects";
  extraBuildInputs = [ alsa-lib ];
}
