{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  libX11,
  libGL,
  libGLU,
  lv2,
}:

let
  nanovgSrc = fetchFromGitHub {
    owner = "memononen";
    repo = "nanovg";
    rev = "077b65e0cf3e22ee4f588783e319b19b0a608065";
    hash = "sha256-Osb8GnQZD532WLh+twmwsUdJ3W7hh2s6HFND7si+wzU=";
  };

  puglSrc = fetchFromGitHub {
    owner = "lv2";
    repo = "pugl";
    rev = "9fd2cd2c086665e470e31af8d1169a1a8e51c934";
    hash = "sha256-cF9LgwT5D0zLFqy5AIOa1J6aFqdGTV+KNddQNfyKwIw=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "aether";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "Dougal-s";
    repo = "Aether";
    tag = "v${finalAttrs.version}";
    hash = "sha256-8hMSbOdoCvPxVz+1WIHnMw1SCpK62XBQvmwGCELLNLY=";
  };

  postPatch = ''
    rm -rf extern/nanovg extern/pugl
    cp -r --no-preserve=mode,ownership ${nanovgSrc} extern/nanovg
    cp -r --no-preserve=mode,ownership ${puglSrc} extern/pugl
  '';

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    libX11
    libGL
    libGLU
    lv2
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/lv2
    cp -r aether.lv2 $out/lib/lv2/
    runHook postInstall
  '';

  meta = {
    description = "Free and open source, cross-platform algorithmic reverb (LV2)";
    homepage = "https://github.com/Dougal-s/Aether";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
