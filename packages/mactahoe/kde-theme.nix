# MacTahoe KDE theme — SDDM, Kvantum, Aurorae, color schemes, wallpapers
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "mactahoe-kde-theme";
  version = "unstable-2025-11-28";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "MacTahoe-kde";
    rev = "4c0ad8fe730d32c892c84ab0dcf9a104a6fd466d";
    hash = "sha256-6saJ9t1KZeIkCwR6ePKSnJxSsba0XRmck8g8/JDuuBE=";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share
    cp -r sddm $out/share/
    cp -r aurorae $out/share/
    cp -r color-schemes $out/share/
    cp -r Kvantum $out/share/
    cp -r plasma $out/share/
    cp -r wallpapers $out/share/
    runHook postInstall
  '';

  meta = {
    description = "MacTahoe KDE theme with SDDM, Kvantum, and Aurorae components";
    homepage = "https://github.com/vinceliuice/MacTahoe-kde";
    license = lib.licenses.gpl3Only;
  };
}
