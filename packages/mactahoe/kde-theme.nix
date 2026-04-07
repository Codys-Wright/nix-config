# MacTahoe KDE theme — look-and-feel, desktop theme, color schemes,
# aurorae window decorations, Kvantum, SDDM themes, and wallpapers.
#
# Replicates upstream install.sh logic for Nix (the original script
# relies on sed-in-place, UID checks, and /usr writes that don't work
# in a pure build).
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

    share="$out/share"
    mkdir -p "$share"

    # ── Color schemes ────────────────────────────────────────────────
    mkdir -p "$share/color-schemes"
    cp color-schemes/*.colors "$share/color-schemes/"

    # ── Plasma desktop themes ────────────────────────────────────────
    for color in Dark Light; do
      dst="$share/plasma/desktoptheme/MacTahoe-$color"
      mkdir -p "$dst"
      cp -r plasma/desktoptheme/MacTahoe-$color/* "$dst/"
      # Merge shared icons into each variant
      cp -r plasma/desktoptheme/icons "$dst/icons"
    done

    # ── Plasma layout templates ──────────────────────────────────────
    mkdir -p "$share/plasma/layout-templates"
    cp -r plasma/layout-templates/* "$share/plasma/layout-templates/"

    # ── Look-and-feel (global theme) ─────────────────────────────────
    for color in Dark Light; do
      dst="$share/plasma/look-and-feel/com.github.vinceliuice.MacTahoe-$color"
      mkdir -p "$dst"
      cp -r "plasma/look-and-feel/com.github.vinceliuice.MacTahoe-$color"/* "$dst/"
    done

    # ── Aurorae window decorations ───────────────────────────────────
    for color in Dark Light; do
      for scale in "" "-1.25x" "-1.5x"; do
        name="MacTahoe-$color$scale"
        dst="$share/aurorae/themes/$name"
        mkdir -p "$dst"

        # Decoration frame SVGs (scale-specific if present, else base)
        if [ -d "aurorae/MacTahoe-$color$scale" ]; then
          cp aurorae/MacTahoe-$color$scale/*.svg "$dst/"
        else
          cp aurorae/MacTahoe-$color/*.svg "$dst/"
        fi

        # Window button icons
        cp aurorae/icons-$color/*.svg "$dst/"

        # Config rc file
        cp "aurorae/''${color}rc" "$dst/''${name}rc"

        # Metadata — template theme_name → actual name
        sed "s/theme_name/$name/g" aurorae/metadata.desktop > "$dst/metadata.desktop"
        sed "s/theme_name/$name/g" aurorae/metadata.json > "$dst/metadata.json"
      done
    done

    # ── Kvantum theme ────────────────────────────────────────────────
    mkdir -p "$share/Kvantum"
    cp -r Kvantum/MacTahoe "$share/Kvantum/MacTahoe"

    # ── Wallpapers ───────────────────────────────────────────────────
    mkdir -p "$share/wallpapers"
    cp -r wallpapers/MacTahoe "$share/wallpapers/MacTahoe"
    cp -r wallpapers/MacTahoe-Dark "$share/wallpapers/MacTahoe-Dark"
    cp -r wallpapers/MacTahoe-Light "$share/wallpapers/MacTahoe-Light"

    # ── SDDM themes (Plasma 6) ──────────────────────────────────────
    for color in Dark Light; do
      dst="$share/sddm/themes/MacTahoe-$color"
      mkdir -p "$dst"
      cp -r sddm/MacTahoe-6.0/* "$dst/"
      cp "sddm/images/Background-$color.jpeg" "$dst/Background.jpeg"
      cp "sddm/images/Preview-$color.jpeg" "$dst/Preview.jpeg"
      substituteInPlace "$dst/metadata.desktop" \
        --replace-fail "Name=MacTahoe" "Name=MacTahoe-$color" \
        --replace-fail "Theme-Id=MacTahoe" "Theme-Id=MacTahoe-$color"
      substituteInPlace "$dst/Main.qml" \
        --replace-fail "MacTahoe" "MacTahoe-$color"
    done

    runHook postInstall
  '';

  meta = {
    description = "MacTahoe KDE theme with look-and-feel, desktop theme, aurorae, Kvantum, SDDM, and wallpapers";
    homepage = "https://github.com/vinceliuice/MacTahoe-kde";
    license = lib.licenses.gpl3Only;
  };
}
