{
  lib,
  python3Packages,
  fetchgit,
}:
python3Packages.buildPythonApplication {
  pname = "mioctl";
  version = "0-unstable-2024-08-25";
  format = "other";

  src = fetchgit {
    url = "https://codeberg.org/pmatilai/mioctl";
    rev = "a6f9283794ec45d9dd03234c51da0ff2cf85a164";
    hash = "sha256-o37fCviqDgfarY9c5kOs94gKM885B+JqmlohUS+kTDM=";
  };

  dependencies = with python3Packages; [
    mido
    python-rtmidi # mido's default backend
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 mioctl $out/bin/mioctl
    runHook postInstall
  '';

  meta = {
    description = "CLI for configuring iConnectivity Mio X-series MIDI interfaces (mioXM/mioXL)";
    homepage = "https://codeberg.org/pmatilai/mioctl";
    license = lib.licenses.gpl3Plus;
    mainProgram = "mioctl";
    platforms = lib.platforms.linux;
  };
}
