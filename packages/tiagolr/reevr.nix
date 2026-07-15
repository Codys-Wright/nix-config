{ callPackage }:
callPackage ./mk-plugin.nix { } {
  pname = "reevr";
  targetName = "REEVR";
  version = "1.4.0";
  rev = "e4d553a72c960ad163a34fab574a81102c52ce4e";
  hash = "sha256-NXZNNwRNHTk9TeTzLSXBfpMdZ4dvtLBw3eJFnTSVd2Y=";
  juceRev = "10a589619b452c261b2940767eb253171eb5a823";
  juceHash = "sha256-nl4pUSkUKqpMoehzq0MS5pjHpYDkrFpUsY8BwpQObCM=";
  description = "12-step sequenced convolution reverb (VST3/LV2)";
  homepage = "https://github.com/tiagolr/reevr";
}
