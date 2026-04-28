{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  alsa-lib,
}:
rustPlatform.buildRustPackage {
  pname = "inferno";
  version = "0.5.0-unstable-2026-04-27";

  src = fetchFromGitHub {
    owner = "FastTrackStudios";
    repo = "inferno";
    rev = "309f534374e425badc9d3594911a46a36ecad838";
    hash = "sha256-3c0C94yEzgX2h10bIxUG+QLRuV+Edomb7FukpKm1Hh0=";
    fetchSubmodules = true;
  };

  cargoHash = "sha256-oQER1LDfLRxiSfeRCb9abKkkIIkDoES34NaolM4y1j4=";

  cargoBuildFlags = [
    "-p"
    "inferno2pipe"
    "-p"
    "alsa_pcm_inferno"
  ];

  doCheck = false;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ alsa-lib ];

  installPhase = ''
    runHook preInstall

    releaseDir="target/${stdenv.hostPlatform.rust.cargoShortTarget}/release"
    if [ ! -d "$releaseDir" ]; then
      releaseDir=$(find target -maxdepth 3 -type d -path '*/release' | head -n1)
    fi

    install -Dm755 "$releaseDir/inferno2pipe" $out/bin/inferno2pipe
    install -Dm755 "$releaseDir/libasound_module_pcm_inferno.so" \
      $out/lib/alsa-lib/libasound_module_pcm_inferno.so

    install -Dm644 alsa_pcm_inferno/asoundrc $out/share/inferno/asoundrc.example
    install -Dm644 alsa_pcm_inferno/README.md $out/share/doc/inferno/alsa_pcm_inferno.md
    install -Dm644 README.md $out/share/doc/inferno/README.md
    install -Dm644 os_integration/systemd_allow_clock.conf \
      $out/share/inferno/systemd_allow_clock.conf

    runHook postInstall
  '';

  meta = {
    description = "Unofficial implementation of the Dante protocol with inferno2pipe and ALSA PCM plugin";
    homepage = "https://github.com/FastTrackStudios/inferno";
    license = with lib.licenses; [
      gpl3Plus
      agpl3Plus
    ];
    platforms = lib.platforms.linux;
    mainProgram = "inferno2pipe";
  };
}
