{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  cmake,
  ninja,
  pkg-config,
  libX11,
  libXext,
  libXinerama,
  libXrandr,
  libXcursor,
  libGL,
  freetype,
  fontconfig,
  curl,
  alsa-lib,
  webkitgtk_4_1,
}:

let
  juceSrc = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "8d935b25b287cf23251d6973afcae6c7b5607710"; # develop, pinned by upstream submodule
    hash = "sha256-Xd3jBuHqbRWVLsMGsH1ykZHG63ubcBeiiPf5e8oDN28=";
  };

  clapJuceExtensionsSrc = fetchFromGitHub {
    owner = "free-audio";
    repo = "clap-juce-extensions";
    rev = "d3bc57b280912fab13556144d6db3a5f6c531f6b";
    hash = "sha256-53r/geseQugMMLKXLDEZjhiCnpC+xELa72UuxWBv/O4=";
    fetchSubmodules = true;
  };

  melatoninInspectorSrc = fetchFromGitHub {
    owner = "sudara";
    repo = "melatonin_inspector";
    rev = "8f0b23aae1ac9ca185fa62c09cfde477fc2dda00";
    hash = "sha256-yQsxi0ha6RveMHLaq68gCXFmx+OPk4cvhuvawHr68hQ=";
  };

  cmakeIncludesSrc = fetchFromGitHub {
    owner = "sudara";
    repo = "cmake-includes";
    rev = "3c9a8210a456288b0679fdaf27e419a2ebe66fee";
    hash = "sha256-ks1kepFjXgcgTsuv9GmdjMzGREyPgA0jPjhd9DxKVMk=";
  };

  # cmake-includes' CPM.cmake unconditionally file(DOWNLOAD)s this at
  # `include(CPM)` time (not just when CPMAddPackage is actually called).
  # Pre-place it where CPM_SOURCE_CACHE expects it so that turns into a
  # no-op hash-verified skip instead of a sandboxed network fetch.
  cpmVersion = "0.40.2";
  cpmScript = fetchurl {
    url = "https://github.com/cpm-cmake/CPM.cmake/releases/download/v${cpmVersion}/CPM.cmake";
    hash = "sha256-yM3DLAOBZTjOInge1ylk3IZLKjSjENO3EEgSpcotg10=";
  };
in
stdenv.mkDerivation {
  pname = "dumumub-0000006";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "hugh-buntine";
    repo = "dumumub-0000006";
    tag = "v1.0.1";
    hash = "sha256-p0x1pkwsuQa1qb7PT5ofWiHDpBvW48nIh/cfWw/Gc/0=";
  };

  postPatch = ''
    rm -rf JUCE modules/clap-juce-extensions modules/melatonin_inspector cmake
    cp -r --no-preserve=mode,ownership ${juceSrc} JUCE
    cp -r --no-preserve=mode,ownership ${clapJuceExtensionsSrc} modules/clap-juce-extensions
    cp -r --no-preserve=mode,ownership ${melatoninInspectorSrc} modules/melatonin_inspector
    cp -r --no-preserve=mode,ownership ${cmakeIncludesSrc} cmake

    mkdir -p cpm-cache/cpm
    cp ${cpmScript} cpm-cache/cpm/CPM_${cpmVersion}.cmake

    # Tests/Benchmarks pull in Catch2 via CPMAddPackage — a real network
    # fetch we don't want and don't need for packaging the plugin binary.
    substituteInPlace CMakeLists.txt \
      --replace-fail "include(Tests)" "" \
      --replace-fail "include(Benchmarks)" ""
  '';

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
    libGL
    freetype
    fontconfig
    curl
    alsa-lib
    webkitgtk_4_1
  ];

  preConfigure = ''
    cmakeFlagsArray+=("-DCPM_SOURCE_CACHE=$PWD/cpm-cache")
    # COPY_PLUGIN_AFTER_BUILD copies into $HOME/.vst3 + $HOME/.clap post-build.
    export HOME=$TMPDIR
  '';

  # Fontconfig error: Cannot load default config file: No such file: (null)
  env.FONTCONFIG_FILE = "${fontconfig.out}/etc/fonts/fonts.conf";

  # JUCE (vendored as a submodule) is compiled with -flto; linking plain
  # object files against it fails with "undefined reference" for every
  # JUCE symbol. Fat LTO objects keep both forms so the link succeeds.
  env.NIX_CFLAGS_COMPILE = "-ffat-lto-objects";

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    pushd dumumub-0000006_artefacts/Release
      mkdir -p $out/lib/vst3
      cp -r VST3/*.vst3 $out/lib/vst3/
      mkdir -p $out/lib/clap
      cp -r CLAP/*.clap $out/lib/clap/
    popd

    runHook postInstall
  '';

  meta = {
    description = "Orbit granular synthesizer (VST3/CLAP)";
    homepage = "https://github.com/hugh-buntine/dumumub-0000006";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
}
