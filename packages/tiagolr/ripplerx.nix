{
  callPackage,
  fetchFromGitHub,
}:
let
  mtsEspSrc = fetchFromGitHub {
    owner = "ODDSound";
    repo = "MTS-ESP";
    rev = "2d7c013ebf4a076c35811e62293e8f819d053a91";
    hash = "sha256-qgVRr8KI8U3qoazS+jppdvP1s+EyjK5S82rBeJMKuh0=";
  };
in
callPackage ./mk-plugin.nix { } {
  pname = "ripplerx";
  targetName = "RipplerX";
  version = "1.5.9";
  rev = "06ae8dcba97057a7ca9c2d9d7de5f8a5d370ecaa";
  hash = "sha256-wGTnYS8TDnFNFM6qTDQECnYpre5sPJy1UOPey+uUMC4=";
  # ripplerx pins its own JUCE commit, different from the other 4 plugins.
  juceRev = "51a8a6d7aeae7326956d747737ccf1575e61e209";
  juceHash = "sha256-uwZVBrvb5O9LEh00y93UeEu4u4rd+tLRCdQdxsMpXNg=";
  extraPostPatch = ''
    rm -rf libs/MTS-ESP
    cp -r --no-preserve=mode,ownership ${mtsEspSrc} libs/MTS-ESP
  '';
  description = "Physically modelled string/tube synthesizer (VST3/LV2)";
  homepage = "https://github.com/tiagolr/ripplerx";
}
