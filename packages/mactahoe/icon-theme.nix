# MacTahoe icon theme
{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  gtk3,
  hicolor-icon-theme,
  jdupes,
  boldPanelIcons ? false,
  themeVariants ? [ ], # default|blue|purple|green|red|orange|yellow|grey|nord|all
}:

let
  pname = "mactahoe-icon-theme";
in
lib.checkListOfEnum "${pname}: theme variants"
  [
    "default"
    "blue"
    "purple"
    "green"
    "red"
    "orange"
    "yellow"
    "grey"
    "nord"
    "all"
  ]
  themeVariants

  stdenvNoCC.mkDerivation
  rec {
    inherit pname;
    version = "2025-11-27";

    src = fetchFromGitHub {
      owner = "vinceliuice";
      repo = "MacTahoe-icon-theme";
      rev = "eb6d04553bb8fff1166de7f0b08c93e8b9f0eb13";
      hash = "sha256-tgZMflZqdaTmFvf3zArpwlD+i3SPHt0PsMjgMc20+PM=";
    };

    nativeBuildInputs = [
      gtk3
      jdupes
    ];

    buildInputs = [ hicolor-icon-theme ];

    # These fixup steps are slow and unnecessary
    dontPatchELF = true;
    dontRewriteSymlinks = true;
    dontDropIconThemeCache = true;

    postPatch = ''
      patchShebangs install.sh

      # Remove cursor installation - we package cursors separately
      substituteInPlace install.sh \
        --replace-fail 'install_theme && install_cursor_theme' 'install_theme'
    '';

    installPhase = ''
      runHook preInstall

      ./install.sh --dest $out/share/icons \
        --name MacTahoe \
        ${lib.optionalString (themeVariants != [ ]) ("--theme " + toString themeVariants)} \
        ${lib.optionalString boldPanelIcons "--bold"}

      jdupes --link-soft --recurse $out/share

      runHook postInstall
    '';

    meta = {
      description = "MacOS Tahoe style icon theme for Linux desktops";
      homepage = "https://github.com/vinceliuice/MacTahoe-icon-theme";
      license = lib.licenses.gpl3Plus;
      platforms = lib.platforms.linux;
      maintainers = [ ];
    };
  }
