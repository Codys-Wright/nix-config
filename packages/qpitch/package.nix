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

  buildVST3 ? true,
  buildCLAP ? true,
}:

let
  juceSrc = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "d6181bde38d858c283c3b7bf699ce6340c050b5d"; # 8.0.8, pinned by qpitch's JUCE submodule
    hash = "sha256-kp3rMaHWBbEh4UaRMxcLo/DiSJV942OY+LYxh6W7dFc=";
  };

  clapJuceExtensionsSrc = fetchFromGitHub {
    owner = "free-audio";
    repo = "clap-juce-extensions";
    rev = "16e9d4ca7b1e86c76e04584b2c08e85a764bcda8"; # main, pinned for reproducibility
    hash = "sha256-0oV0KR//AfkdcXyjFQIadmKqMdJTzoVWNSFydoQlzO4=";
    fetchSubmodules = true;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "qpitch";
  version = "1.3.1";

  src = fetchFromGitHub {
    owner = "skynse";
    repo = "qpitch";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Er7ViD1KZ5T3oq6yzckdni3LyW44R7xLJ8NjrNK3pfk=";
  };

  postPatch = ''
    rm -rf JUCE clap-juce-extensions
    cp -r --no-preserve=mode,ownership ${juceSrc} JUCE
    cp -r --no-preserve=mode,ownership ${clapJuceExtensionsSrc} clap-juce-extensions
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
    freetype
    fontconfig
  ];

  buildFlags = [
    "--target"
  ]
  ++ lib.optionals buildVST3 [ "QPitch_VST3" ]
  ++ lib.optionals buildCLAP [ "QPitch_CLAP" ];

  # Fontconfig error: Cannot load default config file: No such file: (null)
  env.FONTCONFIG_FILE = "${fontconfig.out}/etc/fonts/fonts.conf";

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    pushd QPitch_artefacts/Release
      ${lib.optionalString buildVST3 ''
        mkdir -p $out/lib/vst3
        cp -r VST3/QPitch.vst3 $out/lib/vst3
      ''}
      ${lib.optionalString buildCLAP ''
        mkdir -p $out/lib/clap
        cp -r CLAP/QPitch.clap $out/lib/clap
      ''}
    popd

    runHook postInstall
  '';

  meta = {
    description = "JUCE pitch-correction plugin with formant preservation (VST3/CLAP)";
    homepage = "https://github.com/skynse/qpitch";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
