# MacTahoe KDE theme - Plasma desktop theme, color schemes, Kvantum, aurorae, wallpapers
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  colorVariants ? [], # light|dark (default: all)
}:

let
  pname = "mactahoe-kde-theme";
in

lib.checkListOfEnum "${pname}: color variants" [ "light" "dark" ] colorVariants

stdenvNoCC.mkDerivation rec {
  inherit pname;
  version = "2025-11-28";

  src = fetchFromGitHub {
    owner = "vinceliuice";
    repo = "MacTahoe-kde";
    rev = "4c0ad8fe730d32c892c84ab0dcf9a104a6fd466d";
    hash = "sha256-6saJ9t1KZeIkCwR6ePKSnJxSsba0XRmck8g8/JDuuBE=";
  };

  postPatch = ''
    patchShebangs install.sh sddm/install.sh

    # Replace UID checks with true for both [ ] and [[ ]] forms
    substituteInPlace install.sh \
      --replace-fail '"$UID" -eq "$ROOT_UID"' true \
      --replace-fail /usr $out

    substituteInPlace sddm/install.sh \
      --replace-fail '"$UID" -eq "$ROOT_UID"' true \
      --replace-fail /usr $out \
      --replace-fail 'REO_DIR="$(cd $(dirname $0) && pwd)"' 'REO_DIR=sddm' \
      --replace-fail 'sudo ' ' '

    substituteInPlace sddm/*/Main.qml \
      --replace-fail /usr $out
  '';

  installPhase = ''
    runHook preInstall

    # Clear name= to avoid Nix derivation name overriding the theme name
    name= ./install.sh \
      ${toString (map (x: "--color " + x) colorVariants)}

    mkdir -p $out/share/sddm/themes
    name= sddm/install.sh

    runHook postInstall
  '';

  meta = {
    description = "MacOS Tahoe like theme for KDE Plasma desktop";
    homepage = "https://github.com/vinceliuice/MacTahoe-kde";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.all;
    maintainers = [];
  };
}
