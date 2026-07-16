{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
  xorg,
  makeWrapper,
  ghidra,
}:
rustPlatform.buildRustPackage {
  pname = "ghidra-cli";
  version = "0-unstable-2024-12-18";

  src = fetchFromGitHub {
    owner = "Codys-Wright";
    repo = "ghidra-cli";
    rev = "503bfc637c309e9af5dae106ebaedc5cadbaf811";
    hash = "sha256-q5u5DpGSU3MI/sk9FWk4SfsSfG7S0Cl/043Br0ppsSE=";
  };

  cargoHash = "sha256-udBEUmx9x1F1U+VDnBwMQVvwslym6gcznNJ6DSyyK2w=";

  # Tests require a running Ghidra instance
  doCheck = false;

  # Rename binary to avoid conflict with ghidra's bin/ghidra
  # and wrap with GHIDRA_INSTALL_DIR pointing to the nix store ghidra
  postInstall = ''
    mv $out/bin/ghidra $out/bin/ghidra-cli
    wrapProgram $out/bin/ghidra-cli \
      --set-default GHIDRA_INSTALL_DIR "${ghidra}/lib/ghidra"
  '';

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];

  buildInputs = [
    openssl
    xorg.libXtst
  ];

  meta = {
    description = "CLI interface for Ghidra reverse engineering tool";
    homepage = "https://github.com/akiselev/ghidra-cli";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "ghidra-cli";
  };
}
