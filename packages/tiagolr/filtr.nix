{ callPackage }:
callPackage ./mk-plugin.nix { } {
  pname = "filtr";
  targetName = "FILTR";
  version = "1.3.0";
  rev = "cd2fc096aa643bbab1485f53be8c67cb2505a7ae";
  hash = "sha256-J4qQowM6k+4TelGV/TwL95I4zq0FeSyRwOEO1VNj0Tw=";
  juceRev = "10a589619b452c261b2940767eb253171eb5a823";
  juceHash = "sha256-nl4pUSkUKqpMoehzq0MS5pjHpYDkrFpUsY8BwpQObCM=";
  description = "12-step sequenced multi-mode filter (VST3/LV2)";
  homepage = "https://github.com/tiagolr/filtr";
}
