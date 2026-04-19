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
    owner = "chris-ritsen";
    repo = "network-audio-controller";
    rev = "1d32c70c2db56abc8a8d83123f72b7b4cf3a4ccf";
    hash = "sha256-GUsXHnDQ2Dy24MshO/chjp5jTA/aBENZIHCimx74rZI=";
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
    homepage = "https://github.com/chris-ritsen/network-audio-controller";
    license = lib.licenses.unlicense;
    mainProgram = "netaudio";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
