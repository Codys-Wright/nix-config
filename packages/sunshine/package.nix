# Vendored from nixpkgs pkgs/by-name/su/sunshine/package.nix, bumped to the
# 2026.516.143833 release (security fix GHSA-ph75-mgxh-mv57) which nixpkgs had
# not yet packaged. Differences from the nixpkgs expression:
#   * version + src hash bumped to v2026.516.143833
#   * upstream now ships package-lock.json, so the vendored lock + its postPatch
#     copy are dropped (buildNpmPackage uses the in-tree lock directly)
#   * npmDepsHash recomputed from the upstream lock
#   * new build inputs for 2026 features: vulkan-headers (Vulkan encode),
#     pipewire (PipeWire/portal/KWin capture), glib (gio)
#   * dropped passthru.updateScript (updater.sh not vendored)
# Revisit / delete this once nixpkgs ships >= 2026.516.143833 (issue #524668).
{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchzip,
  autoPatchelfHook,
  autoAddDriverRunpath,
  makeWrapper,
  buildNpmPackage,
  nixosTests,
  cmake,
  avahi,
  libevdev,
  libpulseaudio,
  libxtst,
  libxrandr,
  libxi,
  libxfixes,
  libxdmcp,
  libx11,
  libxcb,
  openssl,
  libopus,
  boost,
  pkg-config,
  libdrm,
  wayland,
  wayland-scanner,
  libffi,
  libcap,
  libgbm,
  curl,
  pcre,
  pcre2,
  python3,
  libuuid,
  libselinux,
  libsepol,
  libthai,
  libdatrie,
  libxkbcommon,
  libepoxy,
  libva,
  libvdpau,
  libglvnd,
  numactl,
  amf-headers,
  svt-av1,
  vulkan-loader,
  vulkan-headers,
  shaderc,
  pipewire,
  glib,
  libappindicator,
  libnotify,
  miniupnpc,
  nlohmann_json,
  config,
  coreutils,
  udevCheckHook,
  cudaSupport ? config.cudaSupport,
  cudaPackages ? { },
  apple-sdk_15,
}:
let
  inherit (stdenv.hostPlatform) isDarwin isLinux;
  stdenv' = if cudaSupport then cudaPackages.backendStdenv else stdenv;

  # 2026 Sunshine downloads pre-compiled FFmpeg from LizardByte/build-deps at
  # cmake-configure time (no network in the Nix sandbox -> "Could not resolve
  # hostname"). Pre-supply it and point FFMPEG_PREPARED_BINARIES at it so the
  # download branch in cmake/dependencies/ffmpeg.cmake is skipped. Pinned to the
  # build-deps commit the v2026.516.143833 submodule references (tag
  # v2026.516.30821); bump alongside the Sunshine src.
  ffmpegPrebuilt = fetchzip {
    url = "https://github.com/LizardByte/build-deps/releases/download/v2026.516.30821/Linux-x86_64-ffmpeg.tar.gz";
    hash = "sha256-H0VsLwcn/RaVZXH0ewA2ZeIfl9/pH7RFgxLJZiNRC98=";
    stripRoot = false;
  };
in
stdenv'.mkDerivation (finalAttrs: {
  pname = "sunshine";
  version = "2026.516.143833";

  src = fetchFromGitHub {
    owner = "LizardByte";
    repo = "Sunshine";
    tag = "v${finalAttrs.version}";
    hash = "sha256-3yuhOyW1Rqz4ddZ40z2ZzpAReZQFva0SL595XrnFB60=";
    fetchSubmodules = true;
  };

  # build webui — upstream now ships package-lock.json, so use it directly
  ui = buildNpmPackage {
    inherit (finalAttrs) src version;
    pname = "sunshine-ui";
    npmDepsHash = "sha256-YnNnuAdj/S5LGNytqIsmCApIec8DTWKF6VIJ7AXUctU=";

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -a . "$out"/

      runHook postInstall
    '';
  };

  postPatch = # don't look for npm since we build webui separately
  ''
    substituteInPlace cmake/targets/common.cmake \
      --replace-fail 'find_program(NPM npm REQUIRED)' ""
  ''
  # use system boost instead of FetchContent.
  # FETCH_CONTENT_BOOST_USED prevents Simple-Web-Server from re-finding boost.
  # 2026.516 bumped the pinned boost to 1.89.0.
  + ''
    substituteInPlace cmake/dependencies/Boost_Sunshine.cmake \
      --replace-fail 'set(BOOST_VERSION "1.89.0")' 'set(BOOST_VERSION "${boost.version}")'
    echo 'set(FETCH_CONTENT_BOOST_USED TRUE)' >> cmake/dependencies/Boost_Sunshine.cmake
  ''
  # remove upstream dependency on systemd and udev (paths set via cmakeFlags).
  # The upstream .desktop / .service templates are configured by cmake itself
  # and we ship our own systemd user unit via services.sunshine, so the manual
  # substitutions the nixpkgs expression did (and the files they touched) are
  # not needed here — and 2026 renamed/retemplated them anyway.
  + lib.optionalString isLinux ''
    substituteInPlace cmake/packaging/linux.cmake \
      --replace-fail 'find_package(Systemd)' "" \
      --replace-fail 'find_package(Udev)' ""
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    # 2026: glad generates GL/Vulkan loaders at configure time and needs
    # jinja2 + setuptools (pkg_resources); without them it tries to pip-install
    # (no sandbox network). Supply a Python that already has them.
    (python3.withPackages (ps: [
      ps.jinja2
      ps.setuptools
    ]))
    makeWrapper
  ]
  # 2026: glslc (Vulkan shader compiler) to build the rgb2yuv compute shader
  ++ lib.optionals isLinux [ shaderc ]
  ++ lib.optionals isLinux [
    wayland-scanner
    # Avoid fighting upstream's usage of vendored ffmpeg libraries
    autoPatchelfHook
  ]
  ++ lib.optionals cudaSupport [
    autoAddDriverRunpath
    cudaPackages.cuda_nvcc
    (lib.getDev cudaPackages.cuda_cudart)
  ];

  buildInputs = [
    boost
    curl
    miniupnpc
    nlohmann_json
    openssl
    libopus
  ]
  ++ lib.optionals isLinux [
    avahi
    libevdev
    libpulseaudio
    libx11
    libxcb
    libxfixes
    libxrandr
    libxtst
    libxi
    libdrm
    wayland
    libffi
    libevdev
    libcap
    libdrm
    pcre
    pcre2
    libuuid
    libselinux
    libsepol
    libthai
    libdatrie
    libxdmcp
    libxkbcommon
    libepoxy
    libva
    libvdpau
    numactl
    libgbm
    amf-headers
    svt-av1
    # 2026 release: Vulkan encode, PipeWire/portal/KWin capture, gio
    vulkan-headers
    vulkan-loader
    pipewire
    glib
    libappindicator
    libnotify
  ]
  ++ lib.optionals cudaSupport [
    cudaPackages.cudatoolkit
    cudaPackages.cuda_cudart
  ]
  ++ lib.optionals isDarwin [
    apple-sdk_15
  ];

  runtimeDependencies = lib.optionals isLinux [
    avahi
    libgbm
    libxrandr
    libxcb
    libglvnd
  ];

  cmakeFlags = [
    "-Wno-dev"
    (lib.cmakeBool "BOOST_USE_STATIC" false)
    (lib.cmakeBool "BUILD_DOCS" false)
    (lib.cmakeFeature "SUNSHINE_PUBLISHER_NAME" "nixpkgs")
    (lib.cmakeFeature "SUNSHINE_PUBLISHER_WEBSITE" "https://nixos.org")
    (lib.cmakeFeature "SUNSHINE_PUBLISHER_ISSUE_URL" "https://github.com/NixOS/nixpkgs/issues")
  ]
  # upstream tries to use systemd and udev packages to find these directories in FHS; set the paths explicitly instead
  ++ lib.optionals isLinux [
    # pre-supplied FFmpeg binaries (skips upstream's network download).
    # The build-deps tarball nests everything under an ffmpeg/ subdir, which
    # is where lib/libavcodec.a + include/libavutil live.
    (lib.cmakeFeature "FFMPEG_PREPARED_BINARIES" "${ffmpegPrebuilt}/ffmpeg")
    (lib.cmakeBool "UDEV_FOUND" true)
    (lib.cmakeBool "SYSTEMD_FOUND" true)
    (lib.cmakeFeature "UDEV_RULES_INSTALL_DIR" "lib/udev/rules.d")
    (lib.cmakeFeature "SYSTEMD_USER_UNIT_INSTALL_DIR" "lib/systemd/user")
    (lib.cmakeFeature "SYSTEMD_MODULES_LOAD_DIR" "lib/modules-load.d")
  ]
  ++ lib.optionals (!cudaSupport) [
    (lib.cmakeBool "SUNSHINE_ENABLE_CUDA" false)
  ]
  ++ lib.optionals isDarwin [
    (lib.cmakeFeature "CMAKE_CXX_STANDARD" "23")
    (lib.cmakeFeature "OPENSSL_ROOT_DIR" "${openssl.dev}")
    (lib.cmakeFeature "SUNSHINE_ASSETS_DIR" "sunshine/assets")
    (lib.cmakeBool "SUNSHINE_BUILD_HOMEBREW" true)
  ];

  env = {
    # needed to trigger CMake version configuration
    BUILD_VERSION = "${finalAttrs.version}";
    BRANCH = "master";
    COMMIT = "";
  };

  # copy webui where it can be picked up by build
  preBuild = ''
    cp -r ${finalAttrs.ui}/build ../
  '';

  buildFlags = [
    "sunshine"
  ];

  # redefine installPhase to avoid attempt to build webui
  installPhase = ''
    runHook preInstall

    cmake --install .

    runHook postInstall
  '';

  # allow Sunshine to find libvulkan
  postFixup = lib.optionalString cudaSupport ''
    wrapProgram $out/bin/sunshine \
      --set LD_LIBRARY_PATH ${lib.makeLibraryPath [ vulkan-loader ]}
  '';

  doInstallCheck = isLinux;

  nativeInstallCheckInputs = lib.optionals isLinux [ udevCheckHook ];

  passthru = {
    tests = lib.optionalAttrs isLinux {
      sunshine = nixosTests.sunshine;
    };
  };

  meta = {
    description = "Game stream host for Moonlight";
    homepage = "https://github.com/LizardByte/Sunshine";
    license = lib.licenses.gpl3Only;
    mainProgram = "sunshine";
    maintainers = with lib.maintainers; [
      devusb
      anish
    ];
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
