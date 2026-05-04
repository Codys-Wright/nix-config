{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  qt6,
}:

stdenv.mkDerivation rec {
  pname = "libqatemcontrol";
  version = "unstable-2026-04-09";

  src = fetchFromGitHub {
    owner = "oniongarlic";
    repo = "libqatemcontrol";
    rev = "68847dd14fa028c575b27cb63de00531eebba4d9";
    hash = "sha256-Kj0YbTNiTowXFnkMcVcFZ/K7Bo7O33jFZjOezy+VVzo=";
  };

  nativeBuildInputs = [
    cmake
    ninja
  ];

  buildInputs = [
    qt6.qtbase
  ];

  dontWrapQtApps = true;

  meta = {
    description = "Qt library for controlling Blackmagic Design ATEM switchers";
    homepage = "https://github.com/oniongarlic/libqatemcontrol";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
