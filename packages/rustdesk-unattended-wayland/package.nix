# RustDesk's official "unattended Wayland" build (release asset of 1.5.0):
# captures through DRM/KMS with libdrmtap instead of xdg-desktop-portal, so it
# needs no screen-share dialog and works on niri (whose portal path fails
# RustDesk 1.4.x's PipeWire negotiation, rustdesk#15916).
#
# Layout kept as upstream ships it: the binary runs in place from
# share/rustdesk (bin/rustdesk only execs it), because `rustdesk --service`
# finds its per-session server with `ps aux | grep "rustdesk --server"`, which
# a renamed wrapped binary would break. Libraries go through RUNPATH, not
# LD_LIBRARY_PATH: the service starts the server with `sudo`, which drops LD_*.
# librustdesk dlopens only /usr/lib/rustdesk/libdrmtap.so.0: the NixOS
# module (<fleet.networking/rustdesk>) links that path to lib/rustdesk.
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  wrapGAppsHook3,
  alsa-lib,
  at-spi2-atk,
  cairo,
  curl,
  dbus,
  fontconfig,
  gdk-pixbuf,
  glib,
  gst_all_1,
  gtk3,
  libayatana-appindicator,
  libdrm,
  libepoxy,
  libglvnd,
  libpulseaudio,
  libva,
  libx11,
  libxcb,
  libxfixes,
  libxkbcommon,
  libxtst,
  pango,
  pipewire,
  systemdLibs,
  wayland,
  xdotool,
  zlib,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "rustdesk-unattended-wayland";
  version = "1.5.0";

  src = fetchurl {
    url = "https://github.com/rustdesk/rustdesk/releases/download/${finalAttrs.version}/rustdesk-unattended-wayland-${finalAttrs.version}-x86_64.deb";
    hash = "sha256-nu1en0tHr47UFYXDmcssDShw6AHJlkUzDeoQY62ETgk=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    cairo
    curl
    dbus
    fontconfig
    gdk-pixbuf
    glib
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gtk3
    libdrm
    libepoxy
    libpulseaudio
    libx11
    libxcb
    libxfixes
    libxkbcommon
    libxtst
    pango
    systemdLibs
    wayland
    xdotool
    zlib
  ];

  # autoPatchelf runs by hand in postFixup, so the RUNPATH additions below
  # aren't rewritten after it.
  dontAutoPatchelf = true;

  # wrapGAppsHook3 only collects the env; bin/rustdesk applies it (makeWrapper
  # would otherwise move share/rustdesk/rustdesk aside).
  dontWrapGApps = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/share $out/share
    cp -r usr/lib $out/lib
    rm -rf $out/share/rustdesk/files $out/share/polkit-1
    substituteInPlace $out/share/applications/rustdesk.desktop $out/share/applications/rustdesk-link.desktop \
      --replace-quiet "/usr/bin/rustdesk" "rustdesk"
    runHook postInstall
  '';

  # GStreamer (PipeWire fallback path) finds its plugins through this; the
  # service sets the same variable (passthru.gstPluginPath), since it starts
  # the server from share/rustdesk/rustdesk directly.
  passthru.gstPluginPath = lib.makeSearchPath "lib/gstreamer-1.0" [
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    pipewire
  ];

  postFixup = ''
    autoPatchelf $out
    # librustdesk dlopen()s libdrmtap (bundled) and these, none in DT_NEEDED.
    patchelf --add-rpath $out/lib/rustdesk:${
      lib.makeLibraryPath [
        libayatana-appindicator
        libglvnd
        libva
        xdotool
      ]
    } $out/share/rustdesk/lib/librustdesk.so
    # libdrmtap dlopen()s libEGL.so.1 / libGLESv2.so.2 to detile scanout
    # buffers the CPU can't map (AMD), from its own RUNPATH.
    patchelf --add-rpath ${lib.makeLibraryPath [ libglvnd ]} $out/lib/rustdesk/libdrmtap.so.0.5.8

    mkdir -p $out/bin
    makeWrapper $out/share/rustdesk/rustdesk $out/bin/rustdesk \
      --argv0 rustdesk \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : ${finalAttrs.passthru.gstPluginPath} \
      "''${gappsWrapperArgs[@]}"
  '';

  meta = {
    description = "RustDesk remote desktop, unattended Wayland build (DRM capture via libdrmtap)";
    homepage = "https://github.com/rustdesk/rustdesk";
    license = lib.licenses.agpl3Only;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "rustdesk";
  };
})
