{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
}:
rustPlatform.buildRustPackage {
  pname = "statime";
  version = "0.4.0-unstable-2025-07-18";

  src = fetchFromGitHub {
    owner = "teodly";
    repo = "statime";
    rev = "244f20a56c173b1881f2e5e83652bb8b8209b2ab";
    hash = "sha256-4xlJUGbtumQCFDqMdV87xDIjIcG0f6YvmwrEWHFeXwc=";
    fetchSubmodules = true;
  };

  cargoHash = "sha256-25DPPtByXGdyjGl321HVj3aWcIWZq8ECvLUcOxeQEuU=";

  cargoBuildFlags = [
    "-p"
    "statime-linux"
  ];

  doCheck = false;

  nativeBuildInputs = [ pkg-config ];

  installPhase = ''
    runHook preInstall

    releaseDir="target/${stdenv.hostPlatform.rust.cargoShortTarget}/release"
    if [ ! -d "$releaseDir" ]; then
      releaseDir=$(find target -maxdepth 3 -type d -path '*/release' | head -n1)
    fi

    install -Dm755 "$releaseDir/statime" $out/bin/statime
    if [ -f "$releaseDir/statime-metrics-exporter" ]; then
      install -Dm755 "$releaseDir/statime-metrics-exporter" $out/bin/statime-metrics-exporter
    fi

    install -Dm644 README.md $out/share/doc/statime/README.md
    install -Dm644 inferno-ptpv1.toml $out/share/statime/inferno-ptpv1.toml
    install -Dm644 inferno-ptpv2.toml $out/share/statime/inferno-ptpv2.toml
    install -Dm644 statime.toml $out/share/statime/statime.toml

    runHook postInstall
  '';

  meta = {
    description = "Inferno-oriented Statime fork for Dante/PTP clock synchronization";
    homepage = "https://github.com/teodly/statime";
    license = with lib.licenses; [
      asl20
      mit
    ];
    platforms = lib.platforms.linux;
    mainProgram = "statime";
  };
}
