{ callPackage }:
callPackage ./mk-plugin.nix { } {
  pname = "gate12";
  targetName = "GATE12";
  version = "1.3.3";
  rev = "df652453236fa03859dbd5fb8eb3dde1fb574ab5";
  hash = "sha256-+WZ2aFxHEVbEnW5NM3lNPhi1mXrGM0a+TGcG1CN1bhs=";
  juceRev = "10a589619b452c261b2940767eb253171eb5a823";
  juceHash = "sha256-nl4pUSkUKqpMoehzq0MS5pjHpYDkrFpUsY8BwpQObCM=";
  description = "12-step sequenced tremolo/gate (VST3/LV2)";
  homepage = "https://github.com/tiagolr/gate12";
}
