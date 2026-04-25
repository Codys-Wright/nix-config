{
  lib,
  python3Packages,
  fetchFromGitHub,
}:
python3Packages.buildPythonApplication rec {
  pname = "netaudio";
  version = "0.2.4-unstable-2026-03-31";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "FastTrackStudios";
    repo = "network-audio-controller";
    rev = "756d1bd9b9e0e69fe545546c8a12b31cdd718495";
    hash = "sha256-0dwi57289hvgmswdvk6ipha79drmvrpqpyjbpw68q6ac4q62s";
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
