{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  qt6,
  callPackage,
  libqatemcontrol ? callPackage ../libqatemcontrol/libqatemcontrol.nix { },
}:

stdenv.mkDerivation rec {
  pname = "cuteatum";
  version = "unstable-2025-05-11";

  src = fetchFromGitHub {
    owner = "oniongarlic";
    repo = "cuteatum";
    rev = "49b6614fe6d507eaef4ef488553ed063b69960c3";
    hash = "sha256-0zl8J1p+k7mKD/TH/Jpc0bQsmw1gHKysNX61F4zCOcc=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    libqatemcontrol
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtmqtt
  ];

  cmakeFlags = [
    "-DATEM_LIBRARY=${libqatemcontrol}/lib/libqatemcontrol.so"
  ];

  meta = {
    description = "QtQuick Blackmagic Design ATEM switcher application";
    homepage = "https://github.com/oniongarlic/cuteatum";
    license = lib.licenses.gpl3Plus;
    mainProgram = "cuteatum";
    platforms = lib.platforms.linux;
  };
}
