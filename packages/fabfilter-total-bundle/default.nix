# FabFilter Total Bundle - Professional audio plugins for music production
# Uses wrapWine for persistent Wine prefix and yabridge integration

{ lib
, inputs
, namespace
, pkgs
, fetchurl
, makeDesktopItem
, symlinkJoin
, ... }:
let
  inherit (pkgs) writeShellScriptBin;

  name = "fabfilter-total-bundle";

  # Import wrapWine function
  wrapWine = pkgs.callPackage ./wrapWine.nix {};

  # FabFilter Total Bundle installer
  installer = fetchurl {
    url = "https://cdn-b.fabfilter.com/downloads/fftotalbundlex64.exe";
    sha256 = "sha256-oDwSjWWRQP0gPL+RSStbbWVhTmZM3vRppJJMuSLKbqk=";
  };

  wine = pkgs.wineWowPackages.yabridge;
  wine-bin = "${wine}/bin/wine64";

  # Main FabFilter package using wrapWine
  bin = wrapWine {
    inherit name wine;

    is64bits = true;

    # Install core fonts for proper GUI rendering
    tricks = [ "corefonts" ];

    firstrunScript = ''
      echo "-----------------------------"
      echo "| Installing FabFilter Total Bundle |"
      echo "-----------------------------"

      # Install FabFilter Total Bundle silently
      wine "${installer}" /Unattended /NORESTART

      echo "-------------------------"
      echo "| Installation complete |"
      echo "-------------------------"
    '';

    executable = "$WINEPREFIX/drive_c/Program Files/FabFilter/Uninst.exe";
  };

  # Script to set up yabridge integration
  yabridge-setup-script = writeShellScriptBin "fabfilter-yabridge-setup" ''
    export APP_NAME="fabfilter-yabridge-setup"
    export WINEARCH=win64
    export WINE_NIX_PROFILES="$HOME/.wine-nix-profiles"
    export WINE_NIX="$HOME/.wine-nix" 
    export HOME="$WINE_NIX_PROFILES/${name}"
    export WINEPREFIX="$WINE_NIX/${name}"
    
    if [ ! -d "$WINEPREFIX" ]; then
      echo "FabFilter Wine prefix not found. Please run 'fabfilter-total-bundle' first to install the plugins."
      exit 1
    fi

    echo "Setting up FabFilter plugins for yabridge..."
    
    # Add FabFilter VST directories to yabridge
    echo "Adding FabFilter VST directories to yabridge..."
    yabridgectl add "$WINEPREFIX/drive_c/Program Files/FabFilter"
    
    # Add VST3 directory if it exists
    if [ -d "$WINEPREFIX/drive_c/Program Files/Common Files/VST3" ]; then
      yabridgectl add "$WINEPREFIX/drive_c/Program Files/Common Files/VST3"
    fi
    
    # Sync yabridge to discover the new plugins
    echo "Syncing yabridge to discover FabFilter plugins..."
    yabridgectl sync
    
    echo "FabFilter plugins are now registered with yabridge and ready for your DAW!"
    echo ""
    echo "You can now load FabFilter plugins in your Linux DAW as native plugins."
    echo "The plugins are located in:"
    echo "  VST2: $WINEPREFIX/drive_c/Program Files/FabFilter"
    echo "  VST3: $WINEPREFIX/drive_c/Program Files/Common Files/VST3"
    echo ""
    echo "Note: Using winePackages.yabridge for optimal compatibility!"
  '';

  desktop = makeDesktopItem {
    name = "FabFilter Total Bundle";
    desktopName = "FabFilter Total Bundle";
    type = "Application";
    exec = "${bin}/bin/fabfilter-total-bundle";
    comment = "Professional audio plugins for music production";
    categories = [ "AudioVideo" "Audio" ];
  };

in symlinkJoin {
  name = "fabfilter-total-bundle";
  paths = [bin desktop yabridge-setup-script];
  
  meta = with pkgs.lib; {
    description = "FabFilter Total Bundle - Professional audio plugins for music production";
    homepage = "https://www.fabfilter.com/products/total-bundle";
    license = licenses.unfree;
    maintainers = [ ];
    platforms = [ "x86_64-linux" "i386-linux" ];
  };
}