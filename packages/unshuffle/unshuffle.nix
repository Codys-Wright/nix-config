{
  lib,
  fetchFromGitHub,
  python3,
  cmake,
  makeWrapper,
  libpulseaudio,
  libva,
}:

let
  python = python3.override {
    packageOverrides = _self: _super: { };
  };
in
python.pkgs.buildPythonApplication rec {
  pname = "unshuffle";
  version = "1.0.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "calloga";
    repo = "unshuffle";
    tag = "v${version}";
    hash = "sha256-fZ15JG4fTISBoQDjK3L0Mi/tbeczrXfguAhOjCHLeY4=";
  };

  # The Linux unshuffle_extractor binary that pyproject.toml's data-files
  # entry expects at bin/linux/ ships empty in-tree (populated by upstream's
  # release CI) — build it ourselves and drop it in before the Python build
  # picks up data-files, so it lands at $out/.../share/unshuffle/bin/linux/.
  nativeBuildInputs = [
    cmake
    makeWrapper
  ];

  # cmake's setup hook otherwise takes over configurePhase for the whole
  # derivation; we only want it for the unshuffle_extractor subdirectory,
  # invoked manually below.
  dontUseCmakeConfigure = true;

  postPatch = ''
    # "pathlib" on PyPI is a Python <3.4 backport shim; nixpkgs doesn't
    # package it and it isn't needed (this project requires Python >=3.11,
    # where pathlib is stdlib), but its presence in pyproject.toml's
    # dependency list still fails pythonRuntimeDepsCheckHook.
    substituteInPlace pyproject.toml \
      --replace-fail '"pathlib>=1.0.1",' ""
  '';

  preBuild = ''
    (
      cd unshuffle_extractor
      ${cmake}/bin/cmake -B build -DCMAKE_BUILD_TYPE=Release
      ${cmake}/bin/cmake --build build -j"$NIX_BUILD_CORES"
    )
    mkdir -p bin/linux
    cp unshuffle_extractor/build/unshuffle_extractor bin/linux/
  '';

  build-system = [ python.pkgs.setuptools ];

  dependencies = with python.pkgs; [
    pyside6
    mutagen
    numpy
    hnswlib
  ];

  pythonRelaxDeps = [ "hnswlib" ];

  pythonImportsCheck = [ "unshuffle" ];

  postFixup = ''
    for prog in $out/bin/unshuffle $out/bin/unshuffle-gui; do
      wrapProgram "$prog" \
        --prefix LD_LIBRARY_PATH : ${
          lib.makeLibraryPath [
            libpulseaudio
            libva
          ]
        }
    done
  '';

  meta = {
    description = "Producer-first sample-library staging and migration tool";
    homepage = "https://github.com/calloga/unshuffle";
    license = lib.licenses.mit;
    mainProgram = "unshuffle-gui";
    platforms = lib.platforms.linux;
  };
}
