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
  libGL,
  freetype,
  fontconfig,
  curl,
  alsa-lib,
}:

let
  juceSrc = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "d6181bde38d858c283c3b7bf699ce6340c050b5d"; # 8.0.8
    hash = "sha256-kp3rMaHWBbEh4UaRMxcLo/DiSJV942OY+LYxh6W7dFc=";
  };

  clapJuceExtensionsSrc = fetchFromGitHub {
    owner = "free-audio";
    repo = "clap-juce-extensions";
    rev = "16e9d4ca7b1e86c76e04584b2c08e85a764bcda8"; # main, pinned for reproducibility
    hash = "sha256-0oV0KR//AfkdcXyjFQIadmKqMdJTzoVWNSFydoQlzO4=";
    fetchSubmodules = true;
  };

  dpfSrc = fetchFromGitHub {
    owner = "DISTRHO";
    repo = "DPF";
    rev = "4238e1c7f0351bbe488d79f0899c540543ac7583"; # main, pinned for reproducibility
    hash = "sha256-bgwRbZ+v6/v8UYUhrIurrN1fCxaYz4iFbREoBmvaII4=";
    fetchSubmodules = true;
  };

  dpfWidgetsSrc = fetchFromGitHub {
    owner = "DISTRHO";
    repo = "DPF-Widgets";
    rev = "730da6397904da66d99667c1cb30fc77fc3d794a"; # main, pinned for reproducibility
    hash = "sha256-Pmd2y/WVwNdnBYS8YlvZM07B5qi7tqT5jO8vVzHV+u0=";
  };

  commonNativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  commonBuildInputs = [
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
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "dusk-audio-plugins";
  version = "unstable-2026-07-15";

  src = fetchFromGitHub {
    owner = "dusk-audio";
    repo = "dusk-audio-plugins";
    rev = "94cfee0ddf1c81b54ff7d4882d1ff272d1378c4e"; # main, pinned for reproducibility
    hash = "sha256-WyJN/qo9OrNQm+hb5qO2fZiR5Vm6s45uxackqz2r3RY=";
  };

  postPatch = ''
    mkdir -p external
    rm -rf external/clap-juce-extensions
    cp -r --no-preserve=mode,ownership ${clapJuceExtensionsSrc} external/clap-juce-extensions
  '';

  nativeBuildInputs = commonNativeBuildInputs;
  buildInputs = commonBuildInputs;

  # Only build the plugins Dusk Audio calls "Production Ready" (README).
  # GrooveMind (ML drummer), Convolution Reverb, Tape Echo, DuskVerb,
  # Multi-Synth, DuskAmp and Harmonic Generator are still in active
  # development and/or pull in extra deps (e.g. GrooveMind's ML runtime) —
  # skip them here.
  cmakeFlags = [
    (lib.cmakeFeature "JUCE_PATH" "${juceSrc}")
    (lib.cmakeBool "DUSK_COPY_AFTER_BUILD" false)
    (lib.cmakeBool "BUILD_4K_EQ" true)
    (lib.cmakeBool "BUILD_MULTI_COMP" true)
    (lib.cmakeBool "BUILD_HARMONIC_GENERATOR" false)
    (lib.cmakeBool "BUILD_TAPE_MACHINE" true)
    (lib.cmakeBool "BUILD_GROOVEMIND" false)
    (lib.cmakeBool "BUILD_CONVOLUTION_REVERB" false)
    (lib.cmakeBool "BUILD_MULTI_Q" true)
    (lib.cmakeBool "BUILD_TAPE_ECHO" false)
    (lib.cmakeBool "BUILD_CHORD_ANALYZER" true)
    (lib.cmakeBool "BUILD_SPECTRUM_ANALYZER" true)
    (lib.cmakeBool "BUILD_DUSKVERB" false)
    (lib.cmakeBool "BUILD_MULTI_SYNTH" false)
    (lib.cmakeBool "BUILD_DUSKAMP" false)
  ];

  # Fontconfig error: Cannot load default config file: No such file: (null)
  env.FONTCONFIG_FILE = "${fontconfig.out}/etc/fonts/fonts.conf";

  enableParallelBuilding = true;

  # TapeMachine 2 (the DPF-based successor to the JUCE TapeMachine 1.x built
  # above) isn't wired into the top-level CMakeLists — it's a standalone
  # CMake project under plugins/TapeMachine/dpf-plugin. Build it separately.
  postBuild = ''
    cmake -S ../plugins/TapeMachine/dpf-plugin -B build-tapemachine2 -GNinja \
      -DCMAKE_BUILD_TYPE=Release \
      -DDPF_PATH=${dpfSrc} \
      -DDPFWIDGETS_PATH=${dpfWidgetsSrc} \
      -DDUSK_DPF_INSTALL_LOCAL=OFF
    cmake --build build-tapemachine2
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/{vst3,lv2,clap}

    # Most plugins here (4K EQ, Multi-Comp, TapeMachine, Multi-Q) override
    # JUCE's default per-plugin "<Target>_artefacts/<Config>/<FORMAT>/"
    # layout with a shared RUNTIME/LIBRARY_OUTPUT_DIRECTORY (bin/ for most,
    # lib/ for TapeMachine) — collect from both layouts.
    for artefacts in $(find . -iname '*_artefacts' -maxdepth 4) bin lib; do
      cp -r "$artefacts/VST3/"*.vst3 $out/lib/vst3/ 2>/dev/null || true
      cp -r "$artefacts/LV2/"*.lv2 $out/lib/lv2/ 2>/dev/null || true
      cp -r "$artefacts/CLAP/"*.clap $out/lib/clap/ 2>/dev/null || true
      cp -r "$artefacts/Release/VST3/"*.vst3 $out/lib/vst3/ 2>/dev/null || true
      cp -r "$artefacts/Release/LV2/"*.lv2 $out/lib/lv2/ 2>/dev/null || true
      cp -r "$artefacts/Release/CLAP/"*.clap $out/lib/clap/ 2>/dev/null || true
    done

    cp -r build-tapemachine2/bin/tape_machine_2.vst3 $out/lib/vst3/
    cp -r build-tapemachine2/bin/tape_machine_2.lv2 $out/lib/lv2/
    cp build-tapemachine2/bin/tape_machine_2.clap $out/lib/clap/

    runHook postInstall
  '';

  meta = {
    description = "Collection of professional audio VST3/CLAP/LV2 plugins (4K EQ, Multi-Comp, TapeMachine, Multi-Q, Chord Analyzer, Spectrum Analyzer)";
    homepage = "https://github.com/dusk-audio/dusk-audio-plugins";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
