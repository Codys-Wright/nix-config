# Drive's binaries for macOS (`drive`, the agent, and `drive-node`) from a
# Drive release's own tarball: the build the release makes on airlock
# (FastTrackStudios/drive release.yml, dist-macos), not a second build from
# source. Installing compiles nothing.
#
# Linux uses the release's Nix packages instead (modules/apps/misc/drive.nix),
# which the release pushes to Cachix. The Macs cannot build Drive from
# source cheaply (airlock's internal disk is nearly full), and the tarballs
# are what the release already signs off on.
#
# The version and hashes live in source.json; ./update.sh rewrites it from a
# release's SHA256SUMS, so a bump downloads nothing but that file.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  source = lib.importJSON ./source.json;
  inherit (source) version;
  target =
    {
      aarch64-darwin = "aarch64-apple-darwin";
      x86_64-darwin = "x86_64-apple-darwin";
    }
    .${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "drive-release";
  inherit version;

  src = fetchurl {
    url = "https://github.com/FastTrackStudios/drive/releases/download/v${version}/drive-${version}-${target}.tar.gz";
    hash = source.hashes.${target};
  };

  # The binaries are already linked and signed (ad hoc) by the release.
  dontConfigure = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 drive $out/bin/drive
    install -Dm755 drive-node $out/bin/drive-node
    ln -s drive $out/bin/drive-agent
    runHook postInstall
  '';

  meta = {
    description = "Drive's agent (drive) and node, from the release's macOS tarball";
    homepage = "https://github.com/FastTrackStudios/drive";
    platforms = [
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    mainProgram = "drive";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
