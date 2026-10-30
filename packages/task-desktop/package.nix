# Task's Linux desktop app, from the release's own AppImage: the build the
# release makes once on Task's warm `task-release-desktop` runner
# (FastTrackStudios/task release-assets.yml), not a second, from-scratch Nix
# build of the workspace. Installing compiles nothing.
#
# The version and hash live in source.json; ./update.sh rewrites it from the
# newest release's latest-linux.json (the manifest Task's in-app updater
# reads, which carries the AppImage's sha256), so a bump downloads nothing.
#
# The app's own updater stays idle here: it replaces $APPIMAGE in place, and
# this package runs the extracted image from the read-only store. Updates
# come from bumping source.json.
{
  lib,
  appimageTools,
  fetchurl,
}:

let
  source = lib.importJSON ./source.json;
  pname = "task-desktop";
  inherit (source) version;

  src = fetchurl {
    url = "https://github.com/FastTrackStudios/task/releases/download/v${version}/Task-linux-x86_64.AppImage";
    inherit (source) hash;
  };

  contents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # What the AppImage leaves to the host (scripts/desktop/linux.sh: GTK,
  # WebKitGTK 4.1 and the tray library come from the user's system), plus
  # what Task's own Nix package loads at runtime (desktop-apps.nix).
  extraPkgs =
    pkgs: with pkgs; [
      gtk3
      webkitgtk_4_1
      libsoup_3
      libayatana-appindicator
      glib-networking
      gsettings-desktop-schemas
      libGL
      vulkan-loader
      wayland
      libxkbcommon
    ];

  # WebKitGTK's accelerated compositing gives a white window on NixOS (the
  # same default Task's dev shell and Nix package set).
  profile = ''
    export WEBKIT_DISABLE_COMPOSITING_MODE="''${WEBKIT_DISABLE_COMPOSITING_MODE:-1}"
  '';

  extraInstallCommands = ''
    for d in ${contents}/*.desktop; do
      [ -e "$d" ] || continue
      install -Dm444 "$d" "$out/share/applications/${pname}.desktop"
      substituteInPlace "$out/share/applications/${pname}.desktop" \
        --replace-quiet 'Exec=AppRun' 'Exec=${pname}' \
        --replace-quiet 'Exec=task-app-desktop' 'Exec=${pname}'
    done
    if [ -d ${contents}/usr/share/icons ]; then
      mkdir -p $out/share
      cp -r ${contents}/usr/share/icons $out/share/
    fi
  '';

  meta = {
    description = "Task desktop app (the release AppImage, wrapped)";
    homepage = "https://github.com/FastTrackStudios/task";
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
