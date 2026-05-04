{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  cairo,
  dbus,
  fontconfig,
  gdk-pixbuf,
  glib,
  gtk3,
  libappindicator-gtk3,
  libsoup_3,
  libxkbcommon,
  openssl,
  systemd,
  gst_all_1,
  webkitgtk_4_1,
}:

let
  gstPlugins = with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
  ];
in
stdenv.mkDerivation rec {
  pname = "opendeck";
  version = "2.12.0";

  src = fetchurl {
    url = "https://github.com/nekename/OpenDeck/releases/download/v${version}/opendeck_${version}_amd64.deb";
    hash = "sha256-p+NCR3QzUXu8O/A4qdFXHGKxmrqOk+zLVVCoI7jhhKE=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    cairo
    dbus
    fontconfig
    gdk-pixbuf
    glib
    gtk3
    libappindicator-gtk3
    libsoup_3
    libxkbcommon
    openssl
    systemd
    webkitgtk_4_1
  ]
  ++ gstPlugins;

  gstPluginPath = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" [
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/* $out/

    if [ -d etc/udev/rules.d ]; then
      install -Dm644 etc/udev/rules.d/*.rules -t $out/etc/udev/rules.d
    fi

    wrapProgram $out/bin/opendeck \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libappindicator-gtk3 ]} \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$gstPluginPath"

    runHook postInstall
  '';

  meta = {
    description = "Linux software for Elgato Stream Deck and compatible stream controllers";
    homepage = "https://github.com/nekename/OpenDeck";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "opendeck";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
