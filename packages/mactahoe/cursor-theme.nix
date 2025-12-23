# MacTahoe cursor theme - pre-built cursors from MacTahoe-icon-theme repo
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:

stdenvNoCC.mkDerivation rec {
  pname = "mactahoe-cursor-theme";
  version = "2025-11-27";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "MacTahoe-icon-theme";
    rev = "eb6d04553bb8fff1166de7f0b08c93e8b9f0eb13";
    hash = "sha256-tgZMflZqdaTmFvf3zArpwlD+i3SPHt0PsMjgMc20+PM=";
  };

  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/icons/MacTahoe-cursors
    mkdir -p $out/share/icons/MacTahoe-dark-cursors

    cp -r cursors/dist/* $out/share/icons/MacTahoe-cursors/
    cp -r cursors/dist-dark/* $out/share/icons/MacTahoe-dark-cursors/

    runHook postInstall
  '';

  meta = {
    description = "MacOS Tahoe style cursor theme for Linux";
    homepage = "https://github.com/vinceliuice/MacTahoe-icon-theme";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}
