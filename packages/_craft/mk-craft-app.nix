# Builder shared by the ArtCraft apps nixpkgs doesn't package yet
# (filmcraft, effectcraft, designcraft, figcraft). Every storytold app ships
# the same release layout, so this mirrors their packaging/linux/package.sh:
# `cargo build -p <app> -p <app>-cli`, then the desktop file, MIME types,
# AppStream metadata and hicolor icons from packaging/linux/ and assets/.
#
# winit, wgpu and rfd dlopen the windowing/GPU/dbus libraries, so nothing
# links them; the wrapper puts them on LD_LIBRARY_PATH, and
# autoAddDriverRunpath lets wgpu find the NixOS Vulkan/GL driver.
#
# Drop an app here (and its packages/<name>/) once nixpkgs gains it — the
# fleet-packages collision guard throws when that happens.
{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  makeWrapper,
  wayland-scanner,
  autoAddDriverRunpath,
  desktop-file-utils,
  versionCheckHook,
  craft-fonts,
  wayland,
  libxkbcommon,
  libx11,
  libxcb,
  libxcursor,
  libxi,
  libxrandr,
  vulkan-loader,
  libglvnd,
  dbus,
}:

{
  pname,
  version,
  hash,
  cargoHash,
  # Date of the GitHub release, for the AppStream <release> entry.
  releaseDate,
  description,
  homepage ? "https://getartcraft.com/apps/${pname}",
  extraBuildInputs ? [ ],
  # Extra libraries the app dlopens (e.g. libva for FilmCraft's decoders).
  extraRuntimeLibs ? [ ],
}:

let
  appId = "ai.storyteller.${pname}";

  runtimeLibs = [
    libxkbcommon
    wayland
    libx11
    libxcb
    libxcursor
    libxi
    libxrandr
    vulkan-loader
    libglvnd
    dbus
  ]
  ++ extraRuntimeLibs;

  binaries = [
    pname
    "${pname}-cli"
  ];
in
rustPlatform.buildRustPackage (finalAttrs: {
  inherit pname version cargoHash;

  __structuredAttrs = true;
  strictDeps = true;

  src = fetchFromGitHub {
    owner = "storytold";
    repo = pname;
    tag = "v${finalAttrs.version}";
    inherit hash;
  };

  # The egui fork is [patch]ed wholesale, so Cargo.lock lists the crates
  # nothing uses (egui_demo_lib, …) as [[patch.unused]]. The vendor dir
  # skips those and offline cargo then rejects the [patch]; drop them.
  postPatch = ''
    for crate in $(awk '/^\[\[patch\.unused\]\]/ { getline; gsub(/name = |"/, ""); print }' Cargo.lock); do
      sed -i "/^$crate = { git/d" Cargo.toml
    done
  '';

  cargoBuildFlags = lib.concatMap (b: [
    "-p"
    b
  ]) binaries;

  # The suites need GPU and test corpora the sandbox doesn't have.
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
    makeWrapper
    wayland-scanner
    autoAddDriverRunpath
    desktop-file-utils
  ];

  buildInputs = [
    wayland
    libxkbcommon
    libx11
    libxcb
    libxcursor
    libxi
    libxrandr
  ]
  ++ extraBuildInputs;

  # Embedded fonts for non-Latin scripts, as the official releases ship them.
  # Apps that don't read CRAFT_FONTS_DIR ignore it.
  env = {
    CRAFT_FONTS_DIR = "${craft-fonts}";
    CRAFT_FONTS_REQUIRED = "1";
  };

  postInstall = ''
    install -Dm644 packaging/linux/${appId}.desktop $out/share/applications/${appId}.desktop
    install -Dm644 packaging/linux/${appId}.mime.xml $out/share/mime/packages/${appId}.xml
    mkdir -p $out/share/icons
    cp -R assets/app-icon/hicolor $out/share/icons/
    install -d $out/share/metainfo
    substitute packaging/linux/${appId}.metainfo.xml.in $out/share/metainfo/${appId}.metainfo.xml \
      --subst-var-by VERSION ${finalAttrs.version} \
      --subst-var-by DATE ${releaseDate}
    desktop-file-validate $out/share/applications/${appId}.desktop

    for bin in ${lib.concatMapStringsSep " " (b: "$out/bin/${b}") binaries}; do
      wrapProgram "$bin" --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath runtimeLibs}"
    done
  '';

  # The GUI needs a display; the headless CLI shares its version.
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/${pname}-cli";
  doInstallCheck = true;

  passthru = { inherit runtimeLibs; };

  meta = {
    inherit description homepage;
    changelog = "https://github.com/storytold/${pname}/releases/tag/v${finalAttrs.version}";
    # Bundled fonts and assets: see ATTRIBUTION.md / NOTICE upstream.
    license = with lib.licenses; [
      mit
      asl20
      ofl
    ];
    sourceProvenance = with lib.sourceTypes; [ fromSource ];
    platforms = lib.platforms.linux;
    mainProgram = pname;
  };
})
