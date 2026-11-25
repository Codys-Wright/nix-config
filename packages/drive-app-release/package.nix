# Drive.app, the desktop app (in the menu bar, with the File Provider
# extension that puts Drive in Finder), from a Drive release: the zip the
# release bundles, signs and notarizes on airlock (FastTrackStudios/drive
# macos/bundle-app.sh). Nothing is built or re-signed here, so the
# signature stays the release's.
#
# The version and hashes are drive-release's source.json (`apps`), which
# packages/drive-release/update.sh rewrites.
{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

let
  source = lib.importJSON ../drive-release/source.json;
  inherit (source) version;
  target =
    {
      aarch64-darwin = "aarch64-apple-darwin";
      x86_64-darwin = "x86_64-apple-darwin";
    }
    .${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "drive-app-release";
  inherit version;

  src = fetchurl {
    url = "https://github.com/FastTrackStudios/drive/releases/download/v${version}/Drive-${version}-${target}.zip";
    hash = source.apps.${target};
  };

  nativeBuildInputs = [ unzip ];
  sourceRoot = ".";

  # Signed, notarized and stapled: changing a byte breaks it.
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/Applications
    cp -R Drive.app $out/Applications/
    runHook postInstall
  '';

  meta = {
    description = "Drive.app (the desktop app and its File Provider extension), from the release";
    homepage = "https://github.com/FastTrackStudios/drive";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
