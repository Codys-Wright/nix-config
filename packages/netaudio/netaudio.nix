{
  lib,
  python3Packages,
  fetchFromGitHub,
}:
python3Packages.buildPythonApplication rec {
  pname = "netaudio";
  version = "0.2.4-unstable-2026-04-27";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "FastTrackStudios";
    repo = "network-audio-controller";
    rev = "e52345e";
    hash = "sha256-S7IV41+H+b1Xq95XdZXuVps6Hx0tPQkzc27qcDIjSes=";
  };

  build-system = with python3Packages; [
    hatchling
  ];

  dependencies = with python3Packages; [
    zeroconf
    ifaddr
    sqlitedict
    typer
    rich
    pyyaml
    pynacl
  ];

  nativeCheckInputs = with python3Packages; [
    pytestCheckHook
  ];

  disabledTests = [
    # Upstream tests exercise real Dante/mDNS/network behavior and are not
    # appropriate for deterministic package builds.
  ];
  doCheck = false;

  pythonImportsCheck = [ "netaudio" ];

  meta = {
    description = "CLI for managing Dante/network audio devices";
    homepage = "https://github.com/FastTrackStudios/network-audio-controller";
    license = lib.licenses.unlicense;
    mainProgram = "netaudio";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
