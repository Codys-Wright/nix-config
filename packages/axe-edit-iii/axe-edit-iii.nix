{
  stdenv,
  lib,
  mkWindowsApp,
  wine,
  makeDesktopItem,
  makeDesktopIcon,
  copyDesktopItems,
  copyDesktopIcons,
  requireFile,
  xorg,
}:
let
  version = "1.14.30";
  versionSlug = "v1p14p30";

  # Cursor fix: Wine hides the cursor when hovering over knobs/pots in Axe-Edit III.
  # This overrides XDefineCursor/XUndefineCursor to no-op, keeping the cursor visible.
  cursorFix = stdenv.mkDerivation {
    pname = "axe-edit-iii-cursor-fix";
    inherit version;

    dontUnpack = true;

    nativeBuildInputs = [ xorg.libX11 ];
    buildInputs = [ xorg.libX11 ];

    buildPhase = ''
      cat > cursor-fix.c << 'CEOF'
      #include <X11/X.h>
      int XDefineCursor(void* d, Window w, Cursor c) {
        return 0;
      }
      int XUndefineCursor(void *display, Window w) {
        return 0;
      }
      CEOF
      gcc -rdynamic -shared cursor-fix.c -o libaxe-edit-cursor-fix.so
    '';

    installPhase = ''
      install -Dm755 libaxe-edit-cursor-fix.so $out/lib/libaxe-edit-cursor-fix.so
    '';
  };
in
mkWindowsApp rec {
  inherit wine version;

  pname = "axe-edit-iii";

  src = requireFile {
    name = "Axe-Edit-III-Win-${versionSlug}.exe";
    url = "https://www.fractalaudio.com/axe-edit/";
    hash = lib.fakeHash;
  };

  dontUnpack = true;
  wineArch = "win64";

  enableMonoBootPrompt = false;
  enableInstallNotification = true;
  persistRegistry = true;
  persistRuntimeLayer = false;
  inputHashMethod = "store-path";

  # Persist Axe-Edit settings and presets between launches
  fileMap = {
    "$HOME/.config/axe-edit-iii" = "drive_c/users/$USER/AppData/Roaming/Fractal Audio";
  };

  nativeBuildInputs = [ copyDesktopItems copyDesktopIcons ];

  # Install Axe-Edit III using the Windows installer
  winAppInstall = ''
    wine "${src}" /S
  '';

  # Launch with cursor fix and dwrite override (needed for saving presets)
  winAppRun = ''
    export LD_PRELOAD="${cursorFix}/lib/libaxe-edit-cursor-fix.so"
    export WINEDLLOVERRIDES="dwrite=d"
    wine "$WINEPREFIX/drive_c/Program Files/Fractal Audio/Axe-Edit III/Axe-Edit III.exe" "$ARGS"
  '';

  installPhase = ''
    runHook preInstall
    ln -s $out/bin/.launcher $out/bin/axe-edit-iii
    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = pname;
      desktopName = "Axe-Edit III";
      genericName = "Guitar Amp Editor";
      comment = "Editor/librarian for Fractal Audio Systems Axe-Fx, FM3, and FM9";
      categories = [
        "Audio"
        "Music"
        "Midi"
      ];
    })
  ];

  meta = {
    homepage = "https://www.fractalaudio.com/axe-edit/";
    description = "Editor/librarian for Fractal Audio Systems devices (Axe-Fx, FM3, FM9)";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
