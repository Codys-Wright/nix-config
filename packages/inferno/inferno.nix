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
  version = "0.5.0-unstable-2026-04-06";

  src = fetchFromGitHub {
    owner = "teodly";
    repo = "inferno";
    rev = "3f2bf142e15d01436562e09678763cde89baca9a";
    hash = "sha256-tAnDc452N7yrDTJOkAbJZ58LJ1S6EFYLb0bUEiogW5E=";
    fetchSubmodules = true;
  };

  cargoHash = "sha256-ptspDSLVkJtuOH8i5K3e72TIRN6kzlYq79gwujJpy3Y=";

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
    homepage = "https://github.com/teodly/inferno";
    license = with lib.licenses; [
      gpl3Plus
      agpl3Plus
    ];
    platforms = lib.platforms.linux;
    mainProgram = "inferno2pipe";
  };
}
