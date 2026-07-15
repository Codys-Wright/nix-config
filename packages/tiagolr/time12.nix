{ callPackage }:
callPackage ./mk-plugin.nix { } {
  pname = "time12";
  targetName = "TIME12";
  version = "1.2.3";
  rev = "cb86fd616c10b8368119b01bcdcabc1654899031";
  hash = "sha256-f3LszR/C2ZTziG1t/9+HyQKNxvwAYz+VUKFaeVvTHJU=";
  juceRev = "10a589619b452c261b2940767eb253171eb5a823";
  juceHash = "sha256-nl4pUSkUKqpMoehzq0MS5pjHpYDkrFpUsY8BwpQObCM=";
  description = "MIDI-triggered stutter/glitch/step-repeat effect (VST3/LV2)";
  homepage = "https://github.com/tiagolr/time12";
}
