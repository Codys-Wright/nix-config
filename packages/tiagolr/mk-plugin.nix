# Shared builder for tiagolr's JUCE plugins (time12, filtr, reevr, gate12,
# ripplerx) — same CMake structure: JUCE vendored at libs/JUCE, formats
# VST3+LV2+AU(+Standalone), no CLAP ("planned when there is official JUCE
# support" per each README). No network fetches beyond JUCE/MTS-ESP.
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  libX11,
  libXext,
  libXinerama,
  libXrandr,
  libXcursor,
  freetype,
  fontconfig,
  curl,
  alsa-lib,
}:
{
  pname,
  targetName,
  version,
  rev,
  hash,
  juceRev,
  juceHash,
  description,
  homepage,
  extraPostPatch ? "",
  extraBuildInputs ? [ ],
}:
let
  juceSrc = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = juceRev;
    hash = juceHash;
  };
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "tiagolr";
    repo = pname;
    inherit rev hash;
  };

  postPatch = ''
    rm -rf libs/JUCE
    cp -r --no-preserve=mode,ownership ${juceSrc} libs/JUCE
  ''
  + extraPostPatch;

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    libX11
    libXext
    libXinerama
    libXrandr
    libXcursor
    freetype
    fontconfig
    curl
    alsa-lib
  ]
  ++ extraBuildInputs;

  cmakeFlags = [
    (lib.cmakeBool "BUILD_STANDALONE" false)
  ];

  # COPY_PLUGIN_AFTER_BUILD is hardcoded TRUE (not an option) and copies
  # into $HOME/.vst3 + $HOME/.lv2 post-build; give it a writable HOME.
  preConfigure = ''
    export HOME=$TMPDIR
  '';

  # Fontconfig error: Cannot load default config file: No such file: (null)
  env.FONTCONFIG_FILE = "${fontconfig.out}/etc/fonts/fonts.conf";

  # JUCE (vendored as a submodule, so its -flto usage can't be patched out)
  # is compiled with LTO; linking plain object files against it fails with
  # "undefined reference" for every JUCE symbol. Fat LTO objects keep both
  # the LTO IR and regular machine code so the link succeeds either way.
  env.NIX_CFLAGS_COMPILE = "-ffat-lto-objects";

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    pushd ${targetName}_artefacts/Release
      mkdir -p $out/lib/vst3
      cp -r VST3/*.vst3 $out/lib/vst3/
      mkdir -p $out/lib/lv2
      cp -r LV2/*.lv2 $out/lib/lv2/
    popd

    runHook postInstall
  '';

  meta = {
    inherit description homepage;
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
